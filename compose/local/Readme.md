Local Deployment of ShiftControl
=== 
To test the features of ShiftControl locally, this Docker Compose setup contains ready-to-use configuration using the public images.  
Test users and data are pre-configured.
This setup is not intended for production use.

## Starting the Application
The local stack is now consolidated into a single compose file:

```bash
docker compose up -d
```

If you want to override the built-in defaults, create a `.env` file next to `compose.yml` based on `.env.example`.

## Accessing the Application
Traefik is used to resolve the hostnames for the different services. `nip.io` resolves those hostnames to localhost.
With the provided defaults, the following URLs are available locally:

- ShiftControl: http://shiftcontrol.127.0.0.1.nip.io
- Shiftservice API: http://shiftcontrol.127.0.0.1.nip.io/shiftservice
- Auditservice API: http://shiftcontrol.127.0.0.1.nip.io/auditservice
- Notificationservice API: http://shiftcontrol.127.0.0.1.nip.io/notifications
- Traefik: http://traefik.127.0.0.1.nip.io
- Keycloak: http://keycloak.127.0.0.1.nip.io
- PgAdmin: http://pgadmin.127.0.0.1.nip.io

The default Keycloak admin credentials are:
- Username: admin
- Password: admin

There are also some pre-configured users for testing purposes:
- Username: testadmin, Password: test
- Username: testuser, Password: test  

For more user credentials, refer to `config/realm-dev.json`

## Configuration
Deployment-specific values can be adjusted through `.env`.
Mounted application settings live in `./config`.

The local routing mirrors production more closely now:

- the frontend and backend APIs share one app hostname
- backend services are exposed via path prefixes
- Keycloak remains a separate local host for browser login flows

`http://localhost:4200` remains allowed in the imported realm for frontend development outside Docker.
