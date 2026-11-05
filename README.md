# AVADO Vaultwarden

`vaultwarden.avado.dnp.dappnode.eth`: [Vaultwarden](https://github.com/dani-garcia/vaultwarden)
1.37.5, a password manager server that works with the official Bitwarden apps and browser
extensions, packaged for AVADO.

- Page: **https://vaultwarden.my.ava.do** (http redirects to https: the web vault only works on a
  secure page).
- Data: the `data` volume (`/data`: the SQLite database, attachments, the server's keys).
- Image: the official `vaultwarden/server:1.37.5-alpine`, pinned by digest, plus a small nginx in
  front of it for HTTPS.

## How it is put together

| Part | What |
|---|---|
| `build/Dockerfile` | Official image + nginx + openssl. Vaultwarden listens on `127.0.0.1:8080` inside the container; nginx serves ports 80 (redirect) and 443. No host ports. |
| `build/avado/avado-start.sh` | Start wrapper: starts nginx (restarted if it stops), checks the certificate 15 s after start and then daily, and starts Vaultwarden with `nice 10`. |
| `build/avado/avado-certs.sh` | The `*.my.ava.do` certificate: the box's DAPPMANAGER copy (`http://dappmanager.my.ava.do/my.ava.do.crt`, as AVADO-DNP-Nethermind uses), else `http://iso.ava.do`, else the copy taken at build time. A copy is used only if it is for `*.my.ava.do`, valid for at least another hour and matches its key. |
| `build/avado/app-prestart.sh` | Closes new sign-ups after the first account (see below). |
| `build/avado/nginx.conf.in` | nginx settings (uploads up to 525 MB, websockets for live sync, 404 for `/admin`, a "Vaultwarden is starting" page instead of a 502). |

Fixed in the image: `DOMAIN=https://vaultwarden.my.ava.do`, `ROCKET_ADDRESS=127.0.0.1`,
`ROCKET_PORT=8080`, `IP_HEADER=X-Real-IP`.

## New accounts: only the first one, then invites

- **First account**: while there is no account, the page lets one be made. It is the owner's.
- **After that, sign-ups close by themselves.** `app-prestart.sh` starts a small watcher when
  there is no account yet. A few seconds after the first account appears in the database, it sets
  `signups_allowed = false` through Vaultwarden's admin settings (live, no restart; saved in
  `/data/config.json`). For this the admin page is switched on with a random token made at that
  start and never stored (Vaultwarden then logs a NOTICE about a plain-text `ADMIN_TOKEN`; that is
  expected). Vaultwarden listens only on the container's loopback and nginx answers 404 for
  `/admin`, so the admin page is never reachable from outside. On every later start, with an
  account in the database, Vaultwarden starts with `SIGNUPS_ALLOWED=false` and the admin page off.
  If every account is deleted, the next start opens sign-ups again for a new first account.
- **Family members join through an organisation invite**, which needs no e-mail server. With no
  SMTP set, Vaultwarden stores the invite, and the invited e-mail address may make its account on
  the page even though sign-ups are closed (`Invitation::take` in Vaultwarden's register code).
  Steps for the owner: "New organization" (for example "Family"), "Members", "Invite member",
  enter the e-mail address, "Invite". The family member opens the page and makes an account with
  "Create account" and that address. The owner then opens the menu next to the member and chooses
  "Confirm" (Bitwarden shows a fingerprint phrase to compare). No e-mail is sent; the owner tells
  the member.
- Someone without an invite who tries "Create account" gets "Registration not allowed or user
  already exists". The "Create account" link stays on the page because invited members need it.
- A small gap: someone signing up in the same two seconds as the very first account could also
  get in.

There is no setting for this in the Admin (the earlier `SIGNUPS_ALLOWED` setting is gone). An
"allow new sign-ups for 1 hour" switch was not built: the Admin's settings box can only change
start settings (and saving the same value again does nothing), and a button on an AVADO page
would need its own sign-in to stop anyone on the network from pressing it.

## Resource use and the Ethereum node

AVADO's package format has no memory or CPU limits (the DAPPMANAGER's compose generator does
not pass `mem_limit`/`cpus`). Vaultwarden needs about 50 MB of memory and almost no CPU, and runs
at a lower CPU priority (`nice 10`) than the node.

## Who can reach it

Every device that can open `my.ava.do`: on the AVADO network (AVADO WiFi) or through Remote
Access. There is no port on the home network. The admin page (`/admin`) answers 404 from
outside (see above).

## Updating

Bump the digest and tag in `build/Dockerfile`, `upstream` and `version` in
`dappnode_package.json` and the image tag in `docker-compose.yml`. Read the Vaultwarden release
notes first; the database is migrated automatically on start.

## Licence

The packaging files in this repository are GPL-3.0 (see `LICENSE`). Vaultwarden itself is
AGPL-3.0 and is used unchanged from its official image. The avatar is the Vaultwarden logo from
the Vaultwarden repository.
