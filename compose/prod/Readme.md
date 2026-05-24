Production Deployment of ShiftControl
=== 
TODO

## Prerequisites
It is assumed that following is set up:
- Traefik in an external docker network
- SSL entrypoint `websecure`, exposing port 443  
Depending on the Traefik setup, labels may need to be adjusted.
 
## Configuration

Configure domain names and Traefik network name:
```bash
find . -type f -exec sed -i 's/shiftcontrol.example.com/domain-name/g' {} +
find . -type f -exec sed -i 's/traefik-nw/treafik-network-name/g' {} +
```

After infra has started, log in to keycloak using the default credentials as per docker compose, and import the "prod" realm in as provided in `/config/realm.json` (after replacing the placeholders with sed).  
To assign application admin privileges to an user, add the user attribute `userType` with the value `ADMIN`.  
Volunteers may have no value or `ASSIGNED`.

## Starting the Application
Make sure your Traefik instance is running and configured correctly. To start the application, start the infrastructure first:
```bash
docker compose -f infrastructure.yml up -d
```
This will start keycloak and data services. After the infrastructure is ready, you can start the application itself:
```bash
docker compose -f frontend.yml up -d
docker compose -f backend.yml up -d
```
