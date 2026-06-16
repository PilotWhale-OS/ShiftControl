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
- `shiftservice` and `auditservice` use the same values to log in through the `master` realm with the `admin-cli` client.

Keep those values aligned. If you change the admin username or password in `.env`, the bootstrap admin login and both Spring services must all use that same pair.

If you want to enable the optional pgAdmin service, also set:
```bash
PGADMIN_DEFAULT_EMAIL=admin@admin.com
PGADMIN_DEFAULT_PASSWORD=change-me
```

The Spring Boot services read these variables directly from their YAML config, while the ASP.NET NotificationService receives its domain-specific and secret settings through Docker environment overrides.
Required secrets use Docker Compose's `${VAR:?message}` form, so `docker compose` will fail fast with a clear error if a required secret is missing.

Before starting the stack, render `config/realm.rendered.json` from the checked-in `config/realm.json` template. This keeps the real internal Keycloak client secret out of the tracked file.

Create the rendered realm file with your real domain and the `KEYCLOAK_INTERNAL_CLIENT_SECRET` from `.env`:
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

It also replaces the `internal` client secret in the realm import so it matches `KEYCLOAK_INTERNAL_CLIENT_SECRET`, which `notificationservice` reads from Docker environment overrides.

Do not commit `config/realm.rendered.json`. It is only a local deployment artifact.

The mounted `config/realm.rendered.json` is imported automatically by Keycloak on startup because the container runs with `start --import-realm`.
After the stack is up, log in to Keycloak using the admin credentials from `.env`.
To assign application admin privileges to a user, add the user attribute `userType` with the value `ADMIN`.  
Volunteers may have no value or `ASSIGNED`.

## Starting the Application
Start the full production stack with a single command:
```bash
docker compose up -d
```

If you want to use Cloudflare Tunnel instead of publishing ports on Traefik, uncomment the `cloudflared` service in `compose.yml` and set `CLOUDFLARE_TUNNEL_TOKEN`.
