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
| `build/avado/nginx.conf.in` | nginx settings (uploads up to 525 MB, websockets for live sync). |

Settings the owner can change in the Admin (package > Settings):

| Variable | Default | What |
|---|---|---|
| `SIGNUPS_ALLOWED` | `true` | Set to `false` once the family has its accounts, so nobody else on the AVADO network can make one. |

Fixed in the image: `DOMAIN=https://vaultwarden.my.ava.do`, `ROCKET_ADDRESS=127.0.0.1`,
`ROCKET_PORT=8080`, `IP_HEADER=X-Real-IP`.

## Resource use and the Ethereum node

AVADO's package format has no memory or CPU limits (the DAPPMANAGER's compose generator does
not pass `mem_limit`/`cpus`). Vaultwarden needs about 50 MB of memory and almost no CPU, and runs
at a lower CPU priority (`nice 10`) than the node.

## Who can reach it

Every device that can open `my.ava.do`: on the AVADO network (AVADO WiFi) or through Remote
Access. There is no port on the home network. The admin page (`/admin`) is off (no
`ADMIN_TOKEN`).

## Updating

Bump the digest and tag in `build/Dockerfile`, `upstream` and `version` in
`dappnode_package.json` and the image tag in `docker-compose.yml`. Read the Vaultwarden release
notes first; the database is migrated automatically on start.

## Licence

The packaging files in this repository are GPL-3.0 (see `LICENSE`). Vaultwarden itself is
AGPL-3.0 and is used unchanged from its official image. The avatar is the Vaultwarden logo from
the Vaultwarden repository.
