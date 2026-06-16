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

If you want to enable the optional pgAdmin service, also set:
```bash
PGADMIN_DEFAULT_EMAIL=admin@admin.com
PGADMIN_DEFAULT_PASSWORD=change-me
```

The Spring Boot services read these variables directly from their YAML config, while the ASP.NET NotificationService receives its domain-specific and secret settings through Docker environment overrides.
Required secrets use Docker Compose's `${VAR:?message}` form, so `docker compose` will fail fast with a clear error if a required secret is missing.

Only `config/realm.json` still needs hostname replacement before starting the stack. Do not run a repo-wide `sed`, because several configs intentionally contain environment placeholders now.

Replace the placeholder hostnames in that one file only:
```bash
sed -i 's/shiftcontrol.example.com/your-domain.example.com/g' config/realm.json
```

That replacement updates both:
- `https://shiftcontrol.example.com`
- `https://keycloak.shiftcontrol.example.com`

The mounted `config/realm.json` is imported automatically by Keycloak on startup because the container runs with `start --import-realm`.
After the stack is up, log in to Keycloak using the admin credentials from `.env`.
To assign application admin privileges to a user, add the user attribute `userType` with the value `ADMIN`.  
Volunteers may have no value or `ASSIGNED`.

## Starting the Application
Start the full production stack with a single command:
```bash
docker compose up -d
```

If you want to use Cloudflare Tunnel instead of publishing ports on Traefik, uncomment the `cloudflared` service in `compose.yml` and set `CLOUDFLARE_TUNNEL_TOKEN`.
