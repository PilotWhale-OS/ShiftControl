Production Deployment of ShiftControl
===

This folder is now wired for the production shape below:

- public app URL: `https://shiftcontrol.chaircon.at`
- external OIDC / Keycloak IdP: `https://sso.awoostria.at`
- expected realm: `awoocrew`
- frontend OIDC client id: `shiftcontrol`
- ingress: Cloudflare Tunnel -> Traefik -> containers
- no public `80` / `443` ports on the host
- no bundled Keycloak container in this production compose

The app frontend and the public backend routes live on the same hostname:

- `https://shiftcontrol.chaircon.at/`
- `https://shiftcontrol.chaircon.at/shiftservice`
- `https://shiftcontrol.chaircon.at/auditservice`
- `https://shiftcontrol.chaircon.at/notifications`

## What This Compose Expects

Traefik only listens inside Docker on port `80`.
`cloudflared` is the only ingress component exposed to the outside world, and it creates outbound-only connections to Cloudflare.

For this deployment, you should create one Cloudflare Tunnel route:

- hostname: `shiftcontrol.chaircon.at`
- service URL: `http://traefik:80`

That matches Cloudflare's published-application model for remotely managed tunnels and lets Cloudflare proxy the single public hostname into the internal Traefik router. Sources: [Cloudflare Tunnel setup](https://developers.cloudflare.com/tunnel/setup/), [Tunnel tokens](https://developers.cloudflare.com/tunnel/advanced/tunnel-tokens/).

## Environment File

`compose/prod/.env` is the single source of truth for deployment-specific values.

```bash
SHIFTCONTROL_DOMAIN=shiftcontrol.chaircon.at
SHIFTCONTROL_OIDC_BASE_URL=https://sso.awoostria.at
SHIFTCONTROL_OIDC_REALM=awoocrew
SHIFTCONTROL_OIDC_CLIENT_ID=shiftcontrol
SHIFTCONTROL_OIDC_ISSUER_URI=https://sso.awoostria.at/realms/awoocrew
SHIFTCONTROL_OIDC_TOKEN_URL=https://sso.awoostria.at/realms/awoocrew/protocol/openid-connect/token
POSTGRES_USER=shiftcontrol
POSTGRES_PASSWORD=change-me
POSTGRES_DB=shiftservice
NOTIFICATIONSERVICE_POSTGRES_DB=notificationservice
RABBITMQ_DEFAULT_USER=shiftcontrol
RABBITMQ_DEFAULT_PASS=change-me
SHIFTCONTROL_INTERNAL_API_KEY=change-me-to-a-long-random-secret
KEYCLOAK_INTERNAL_CLIENT_SECRET=
SMTP_ENABLE_SENDING=false
SMTP_HOST=smtp.site.com
SMTP_PORT=587
SMTP_USERNAME=notifications@site.com
SMTP_PASSWORD=
SMTP_FROM_NAME=ShiftControl Notifications
SMTP_FROM_EMAIL=noreply@site.com
SMTP_SECURE_SOCKET_OPTIONS=StartTls
CLOUDFLARE_TUNNEL_TOKEN=change-me
```

Notes:

- `SHIFTCONTROL_INTERNAL_API_KEY` is the recommended service-to-service credential.
- `KEYCLOAK_INTERNAL_CLIENT_SECRET` is optional and only needed if you want the older OAuth `client_credentials` path for internal service calls.
- `SMTP_ENABLE_SENDING=false` keeps email delivery off entirely.
- `SMTP_PASSWORD` is optional as long as email sending stays disabled or your SMTP server does not require authentication.
- `SMTP_SECURE_SOCKET_OPTIONS` should be one of MailKit's enum names such as `None`, `Auto`, `SslOnConnect`, `StartTls`, or `StartTlsWhenAvailable`.
- sender identity is configured through `SMTP_FROM_NAME` and `SMTP_FROM_EMAIL`.

## Recommended Internal Auth Setup

The easiest production setup is:

1. Set a long random value for `SHIFTCONTROL_INTERNAL_API_KEY`.
2. Leave `KEYCLOAK_INTERNAL_CLIENT_SECRET` empty.
3. Start the stack.

With that setup:

- `shiftservice` trusts `X-ShiftControl-Internal-Api-Key`
- `notificationservice` uses the API key when calling `shiftservice`
- `trustservice` uses the API key when calling `shiftservice`

The API key is treated as a trusted internal machine credential with admin-level permissions inside `shiftservice`, exactly as requested.

If you later prefer standards-only machine auth, you can configure a confidential Keycloak client `internal` and fill `KEYCLOAK_INTERNAL_CLIENT_SECRET`. The services already support that as a fallback.

## Keycloak Setup at `sso.awoostria.at`

This compose assumes your external Keycloak issuer is:

- issuer: `https://sso.awoostria.at/realms/awoocrew`
- token endpoint: `https://sso.awoostria.at/realms/awoocrew/protocol/openid-connect/token`

If your realm or browser client id ever changes, update these variables in `.env` together:

- `SHIFTCONTROL_OIDC_REALM`
- `SHIFTCONTROL_OIDC_CLIENT_ID`
- `SHIFTCONTROL_OIDC_BASE_URL`
- `SHIFTCONTROL_OIDC_ISSUER_URI`
- `SHIFTCONTROL_OIDC_TOKEN_URL`

### Frontend Client

Create or verify a browser client with:

- client id: `shiftcontrol`
- flow: Authorization Code
- PKCE: enabled with `S256`
- client authentication: off
- valid redirect URIs: `https://shiftcontrol.chaircon.at/*`
- valid post logout redirect URIs: `https://shiftcontrol.chaircon.at/*`
- web origins: `https://shiftcontrol.chaircon.at`

The frontend also uses silent SSO on:

- `https://shiftcontrol.chaircon.at/silent-check-sso.html`

This browser client is public, so it does not use a client secret.

### Human Admins

Platform admins should simply receive the normal role:

- `admin`

No dedicated `userType=admin` claim is needed anymore.

### Optional Internal OAuth Client

Only if you do not want to use `SHIFTCONTROL_INTERNAL_API_KEY`, create a separate confidential machine client:

- client id: `internal`
- client type: confidential
- service accounts: enabled
- intended flow: `client_credentials`

Its service token should carry the authorities:

- `admin`
- `shiftservice.users.read`

## Cloudflare Tunnel Setup

This compose uses a remotely managed Cloudflare Tunnel token. To wire it up:

1. In Cloudflare Zero Trust, create or open a tunnel.
2. Add a published application route:
- hostname: `shiftcontrol.chaircon.at`
- service: `http://traefik:80`
3. Add a replica and copy the tunnel token.
4. Put that value into:
- `CLOUDFLARE_TUNNEL_TOKEN`
5. Start the stack:

```bash
docker compose up -d
```

Cloudflare documents the token-based Docker run pattern as `cloudflared tunnel --no-autoupdate run --token <TUNNEL_TOKEN>`, which is exactly what the compose file now uses. Sources: [Cloudflare Tunnel token docs](https://developers.cloudflare.com/tunnel/advanced/tunnel-tokens/), [Cloudflare setup guide](https://developers.cloudflare.com/tunnel/setup/).

## Smoke Test

After the containers are up:

1. Open `https://shiftcontrol.chaircon.at`
2. Confirm the frontend loads.
3. Start login and verify the browser is redirected to `https://sso.awoostria.at`.
4. Log in and verify you return to `https://shiftcontrol.chaircon.at`.
5. Confirm API requests succeed under:
- `/shiftservice`
- `/auditservice`
- `/notifications`

## Dev-Only Realm Import Note

`config/realm.json` is now just a reference / dev bootstrap artifact.
It is not used by this production compose file anymore because production now relies on your already hosted Keycloak at `https://sso.awoostria.at`.
