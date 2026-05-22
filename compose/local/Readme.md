Local Deployment of ShiftControl
=== 
To test the features of ShiftControl locally, this docker compose setup contains ready-to-use configuration using the public images.
This setup is not intended for production use.

## Starting the Application
To start the application, start the infrastructure first:
```bash
docker compose -f infrastructure.yml up -d
```
This will start keycloak, traefik and data services. After the infrastructure is ready, you can start the application itself:
```bash
docker compose -f frontend.yml up -d
docker compose -f backend.yml up -d
```

## Accessing the Application
Traefik is used to resolve the hostnames for the different services. nip.io is used to resolve the hostnames to localhost.  
With the provided configuration, you can find following dashboards locally available:
- Traefik: http://traefik.127.0.0.1.nip.io
- Keycloak: http://keycloak.127.0.0.1.nip.io
- PgAdmin: http://pgadmin.127.0.0.1.nip.io
- ShiftControl: http://frontend.127.0.0.1.nip.io

The default Keycloak admin credentials are:
- Username: admin
- Password: admin

There are also some pre-configured users for testing purposes:
- Username: testadmin, Password: test
- Username: testuser, Password: test 
For more user credentials, refer to `config/realm-dev.json`

## Configuration
Container settings can be adjusted in their respective files in `./config`.  
To configure hostnames, the traefik labels in the compose files can be adjusted.
Container configurations in `./config` have to be adjusted accordingly.