Production Deployment of ShiftControl
=== 
This folder now contains a single production compose file: `compose.yml`.

## Prerequisites
It is assumed that Docker and Docker Compose are installed.

The bundled Traefik publishes ports 80 and 443 and exposes the application services by hostname.
If you prefer Cloudflare Tunnel, a commented example is included in `compose.yml`.
 
## Configuration

Set the base domain once, either in your shell or in a local `.env` file next to `compose.yml`:
```bash
SHIFTCONTROL_DOMAIN=shiftcontrol.example.com
SHIFTCONTROL_KEYCLOAK_DOMAIN=keycloak.shiftcontrol.example.com
```

Every hostname is derived from these two values, so changing the environment only requires one or two edits.
The Spring Boot services read the same variable directly from their YAML config, while the ASP.NET NotificationService receives its domain-specific settings through Docker environment overrides.

If you also need to replace config placeholders, run:
```bash
find . -type f -exec sed -i 's/shiftcontrol.example.com/domain-name/g' {} +
```

After infra has started, log in to keycloak using the default credentials as per docker compose, and import the "prod" realm in as provided in `/config/realm.json` (after replacing the placeholders with sed).  
To assign application admin privileges to an user, add the user attribute `userType` with the value `ADMIN`.  
Volunteers may have no value or `ASSIGNED`.

## Starting the Application
Start the full production stack with a single command:
```bash
docker compose up -d
```

If you want to use Cloudflare Tunnel instead of publishing ports on Traefik, uncomment the `cloudflared` service in `compose.yml` and set `CLOUDFLARE_TUNNEL_TOKEN`.
