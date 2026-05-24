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
