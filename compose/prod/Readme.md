Production Deployment of ShiftControl
=== 
This folder now contains a single production compose file: `compose.yml`.

## Prerequisites
It is assumed that Docker and Docker Compose are installed.

The bundled Traefik publishes ports 80 and 443 and exposes exactly two public hostnames:
- `https://${SHIFTCONTROL_DOMAIN}` for the ShiftControl frontend and API paths
- `https://${SHIFTCONTROL_KEYCLOAK_DOMAIN}` for Keycloak

The backend services are routed behind the main ShiftControl domain on path prefixes:
- `/shiftservice`
- `/auditservice`
- `/notifications`

Traefik itself is not published publicly in this production compose file.
An optional pgAdmin service is included as commented configuration in `compose.yml`; if you enable it, it will be exposed on `https://pgadmin.${SHIFTCONTROL_DOMAIN}`.
If you prefer Cloudflare Tunnel, a commented example is included in `compose.yml`.
 
## Configuration

Set the base domain once, either in your shell or in a local `.env` file next to `compose.yml`:
```bash
SHIFTCONTROL_DOMAIN=shiftcontrol.example.com
SHIFTCONTROL_KEYCLOAK_DOMAIN=keycloak.shiftcontrol.example.com
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=change-me
POSTGRES_USER=shiftcontrol
POSTGRES_PASSWORD=change-me
POSTGRES_DB=shiftservice
NOTIFICATIONSERVICE_POSTGRES_DB=notificationservice
RABBITMQ_DEFAULT_USER=shiftcontrol
RABBITMQ_DEFAULT_PASS=change-me
KEYCLOAK_INTERNAL_CLIENT_SECRET=change-me
SMTP_PASSWORD=change-me
```

`KEYCLOAK_ADMIN_USER` and `KEYCLOAK_ADMIN_PASSWORD` are shared credentials:
- Keycloak uses them to create the initial admin account.

`KEYCLOAK_INTERNAL_CLIENT_SECRET` is the shared OAuth2 client secret for trusted
service-to-service calls. The current production stack uses it for internal access
from `notificationservice` and `trustservice` to `shiftservice`.

If you want to enable the optional pgAdmin service, also set:
```bash
PGADMIN_DEFAULT_EMAIL=admin@admin.com
PGADMIN_DEFAULT_PASSWORD=change-me
```

The Spring Boot services read these variables directly from their YAML config.
The ASP.NET NotificationService receives its domain-specific and secret settings
through Docker environment overrides.
Required secrets use Docker Compose's `${VAR:?message}` form, so `docker compose` will fail fast with a clear error if a required secret is missing.

## OAuth / OIDC Setup with Keycloak

This production setup uses Keycloak as both:
- the interactive OIDC provider for browser users
- the OAuth2 token issuer for trusted service-to-service calls

The services no longer use the Keycloak admin API at runtime. Keycloak is only
the identity provider and token issuer.

For this system, there are two relevant OAuth clients:

1. `frontend`
- used by the SPA in the user's browser
- configured in `compose.yml` via:
  - `KEYCLOAK_URL=https://${SHIFTCONTROL_KEYCLOAK_DOMAIN}`
  - `KEYCLOAK_REALM=prod`
  - `KEYCLOAK_CLIENT_ID=frontend`
- intended flow: Authorization Code with PKCE
- expected redirect URIs:
  - `https://${SHIFTCONTROL_DOMAIN}/*`
- expected post-logout redirect URIs:
  - `https://${SHIFTCONTROL_DOMAIN}/*`
- expected web origins:
  - `https://${SHIFTCONTROL_DOMAIN}`
- the frontend also uses:
  - `https://${SHIFTCONTROL_DOMAIN}/silent-check-sso.html`
  for silent SSO checks

2. `internal`
- used only for trusted backend-to-backend calls
- current consumers:
  - `notificationservice`
  - `trustservice`
- intended flow: OAuth2 `client_credentials`
- client id:
  - `internal`
- client secret source:
  - `KEYCLOAK_INTERNAL_CLIENT_SECRET`

The backend services trust OIDC tokens from the `prod` realm as follows:
- `shiftservice` validates JWTs using `oidc.provider.*` in `config/shiftservice.application.yml`
- `auditservice` validates JWTs using `oidc.provider.*` in `config/auditservice.application.yml`
- `notificationservice` validates user JWTs via its `Jwt` settings and obtains service tokens from the `internal` client
- `trustservice` obtains service tokens from the `internal` client

### Recommended Production Setup

For a real deployment, think of the required Keycloak setup like this:

1. Create or use a Keycloak realm named `prod`.
2. Create a browser client `frontend` for the Angular frontend.
3. Create a confidential client `internal` for service-to-service tokens.
4. Configure admin users with the realm role `admin`.
5. Point the deployed containers at that Keycloak realm and those clients.

That is the actual production requirement.

The checked-in realm import in this repository is best treated as a bootstrap
helper and reference configuration:
- useful for local/dev environments
- useful for first-time setup or comparison
- useful to see the exact client and mapper shape the application expects

It should not be read as "production must be operated by re-importing this JSON
on every rollout". In production, the clearer model is to configure Keycloak
deliberately and manage secrets outside tracked files.

### Clear Keycloak Setup Guide

Use these settings when configuring Keycloak for ShiftControl.

1. Create realm `prod`
- realm name: `prod`
- public issuer should end up as:
  - `https://${SHIFTCONTROL_KEYCLOAK_DOMAIN}/realms/prod`

2. Create client `frontend`
- client id: `frontend`
- client type: public browser client
- flow: Authorization Code
- PKCE: enabled with `S256`
- client authentication: off
- valid redirect URIs:
  - `https://${SHIFTCONTROL_DOMAIN}/*`
- valid post logout redirect URIs:
  - `https://${SHIFTCONTROL_DOMAIN}/*`
- web origins:
  - `https://${SHIFTCONTROL_DOMAIN}`
- note:
  - the frontend also uses `https://${SHIFTCONTROL_DOMAIN}/silent-check-sso.html`
    for silent SSO checks, which is covered by the redirect URI wildcard

3. Create client `internal`
- client id: `internal`
- client type: confidential
- client authentication: on
- service accounts: enabled
- intended flow: OAuth2 `client_credentials`
- standard flow: disabled
- implicit flow: disabled
- set the client secret to the same value as:
  - `KEYCLOAK_INTERNAL_CLIENT_SECRET`
- make sure this client can present the authority:
  - `shiftservice.users.read`
  for trusted internal reads against Shiftservice

4. Configure admin role assignment
- the current application recognizes platform admins from the realm role:
  - `admin`
- assign that role to every user who should be a ShiftControl platform admin

5. Point the deployment at Keycloak
- `compose.yml` already configures the frontend with:
  - `KEYCLOAK_URL=https://${SHIFTCONTROL_KEYCLOAK_DOMAIN}`
  - `KEYCLOAK_REALM=prod`
  - `KEYCLOAK_CLIENT_ID=frontend`
- `shiftservice` and `auditservice` already trust:
  - `https://${SHIFTCONTROL_KEYCLOAK_DOMAIN}/realms/prod`
  and the internal in-network issuer
- `notificationservice` and `trustservice` already use:
  - client id `internal`
  - the token endpoint of realm `prod`
  - `KEYCLOAK_INTERNAL_CLIENT_SECRET`

### Keycloak Login and Verification Checklist

After the stack is up, log in to Keycloak using the admin credentials from `.env`.

Verify the following in realm `prod`:

1. `Clients -> frontend`
- `Client authentication` should be off because this is a public browser client
- `Authorization` / `Standard flow` should be enabled
- `Implicit flow` should be disabled
- `Valid redirect URIs` should include:
  - `https://${SHIFTCONTROL_DOMAIN}/*`
- `Valid post logout redirect URIs` should include:
  - `https://${SHIFTCONTROL_DOMAIN}/*`
- `Web origins` should include:
  - `https://${SHIFTCONTROL_DOMAIN}`

2. `Clients -> internal`
- client id should be `internal`
- `Client authentication` should be on
- `Service accounts roles` should be enabled
- the client secret should match `KEYCLOAK_INTERNAL_CLIENT_SECRET`
- the resulting access token should contain:
  - `shiftservice.users.read`

3. `Realm settings`
- realm name should be `prod`
- public issuer should resolve to:
  - `https://${SHIFTCONTROL_KEYCLOAK_DOMAIN}/realms/prod`

4. `Realm roles`
- create or verify the realm role:
  - `admin`
- assign it to the human users who should be platform administrators

### Admin Role Mapping

The current application recognizes platform administrators from normal token
authorities instead of the old dedicated admin claim.

Recommended Keycloak setup:
- create a realm role named `admin`
- assign that role to the human users who should be platform administrators

The backend accepts this admin role from standard token structures such as:
- `realm_access.roles`
- `resource_access.<client>.roles`
- or a flat `roles` claim if your IdP emits one

The legacy `shiftcontrol.admin` scope is still accepted temporarily for rollout
compatibility, but it should be treated as transitional only.

For user-facing tokens:
- `shiftservice` and `auditservice` trust the configured OIDC issuer and its
  allowed issuer list from their mounted YAML config.
- `notificationservice` trusts the configured JWT authority/issuers and uses the
  standard OAuth2 client credentials flow for internal API access.
- `trustservice` uses the same OAuth2 client credentials flow for its internal
  calls to `shiftservice`.

### Optional Bootstrap via Realm Import

If you want a quick bootstrap or a reference setup, the repository includes a
realm template at `config/realm.json`.

Treat this as:
- a convenience for first-time setup
- a dev/local style bootstrap
- a reference for the exact client and mapper structure

Before starting the stack, render `config/realm.rendered.json` from the template
so the real internal client secret is not committed to git.

Create the rendered realm file with your real domain and the
`KEYCLOAK_INTERNAL_CLIENT_SECRET` from `.env`:
```bash
escaped_secret="$(printf '%s' "$KEYCLOAK_INTERNAL_CLIENT_SECRET" | sed 's/[\\/&]/\\&/g')"
sed \
  -e 's/shiftcontrol.example.com/your-domain.example.com/g' \
  -e "s/__KEYCLOAK_INTERNAL_CLIENT_SECRET__/$escaped_secret/g" \
  config/realm.json > config/realm.rendered.json
```

That render step updates both:
- `https://shiftcontrol.example.com`
- `https://keycloak.shiftcontrol.example.com`

It also replaces the `internal` client secret in the realm import so it matches
`KEYCLOAK_INTERNAL_CLIENT_SECRET`, which internal service consumers read from
their Docker environment overrides.

The bootstrap realm template also:
- removes the old dedicated admin claim mapping
- expects human admins to be granted the normal realm role `admin`
- preconfigures the `internal` client to emit the authority
  `shiftservice.users.read` for service-to-service calls

Do not commit `config/realm.rendered.json`. It is only a deployment artifact.

The mounted `config/realm.rendered.json` is imported automatically by Keycloak on
startup because the container runs with `start --import-realm`.

### Smoke Test

Once the stack is running, a healthy OAuth setup should behave like this:
- opening `https://${SHIFTCONTROL_DOMAIN}` shows the frontend
- login redirects the browser to Keycloak on `https://${SHIFTCONTROL_KEYCLOAK_DOMAIN}`
- after login, the browser returns to `https://${SHIFTCONTROL_DOMAIN}`
- the frontend can call `/shiftservice` and `/auditservice` with the user's bearer token
- `notificationservice` and `trustservice` can fetch tokens for client `internal` and call `shiftservice` internal APIs

## Starting the Application
Start the full production stack with a single command:
```bash
docker compose up -d
```

If you want to use Cloudflare Tunnel instead of publishing ports on Traefik, uncomment the `cloudflared` service in `compose.yml` and set `CLOUDFLARE_TUNNEL_TOKEN`.
