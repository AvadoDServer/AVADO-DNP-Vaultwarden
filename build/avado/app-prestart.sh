# Vaultwarden on AVADO: sourced by avado-start.sh before the app starts.
#
# New accounts are closed, except for the very first one (the owner's). Family
# members join through an organisation invite: without an e-mail server,
# Vaultwarden lets an invited e-mail address make its account on the page even
# while sign-ups are closed, and the owner then confirms the member.
#
# - Accounts exist: Vaultwarden starts with SIGNUPS_ALLOWED=false.
# - No account yet: Vaultwarden starts with sign-ups open and a watcher closes
#   them a few seconds after the first account is made. It does that through
#   Vaultwarden's admin settings, so no restart is needed: the admin page is
#   switched on for this only, with a random token made at each start and
#   never stored, Vaultwarden listens only inside this container, and nginx
#   answers 404 for /admin from outside. Once an account exists the admin page
#   stays off on every later start.
AVADO_VW_DB=/data/db.sqlite3

# Number of real accounts (an invited e-mail address that has not made its
# account yet has no password and does not count).
avado_vw_accounts() {
  _n=0
  if [ -s "$AVADO_VW_DB" ]; then
    _n=$(sqlite3 -cmd ".timeout 5000" "$AVADO_VW_DB" \
      "SELECT count(*) FROM users WHERE length(password_hash) > 0" 2>/dev/null) || _n=0
  fi
  case "$_n" in ''|*[!0-9]*) _n=0 ;; esac
  echo "$_n"
}

unset ADMIN_TOKEN DISABLE_ADMIN_TOKEN
if [ "$(avado_vw_accounts)" -gt 0 ]; then
  export SIGNUPS_ALLOWED=false
else
  export SIGNUPS_ALLOWED=true
  # The admin settings file holds only the "sign-ups closed" setting written
  # below (nobody else can reach the admin page). With no account left, it
  # goes, so the next first account can be made.
  if [ -f /data/config.json ] && [ "$(tr -d ' \n' < /data/config.json)" = '{"signups_allowed":false}' ]; then
    rm -f /data/config.json
  fi
  ADMIN_TOKEN=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')
  export ADMIN_TOKEN
  echo "[avado] no account yet: the first account can be made on the page; new sign-ups close by themselves after it"
  (
    _jar=/tmp/avado-vw-admin.cookies
    until curl -fs -o /dev/null http://127.0.0.1:8080/alive; do sleep 1; done
    while :; do
      sleep 2
      [ "$(avado_vw_accounts)" -gt 0 ] || continue
      if curl -fs -o /dev/null -c "$_jar" --data-urlencode "token=$ADMIN_TOKEN" http://127.0.0.1:8080/admin &&
         curl -fs -o /dev/null -b "$_jar" -H 'Content-Type: application/json' \
           -d '{"signups_allowed":false}' http://127.0.0.1:8080/admin/config; then
        rm -f "$_jar"
        echo "[avado] the first account is made: new sign-ups are now closed (family members join through an organisation invite)"
        break
      fi
      rm -f "$_jar"
      echo "[avado] could not close new sign-ups yet; trying again in 30 s" >&2
      sleep 30
    done
    # Stay (an ended helper would linger as a zombie under Vaultwarden).
    while :; do sleep 86400; done
  ) &
fi
