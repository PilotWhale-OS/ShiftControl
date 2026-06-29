# ShiftControl Helm Chart

This chart deploys the production ShiftControl stack on Kubernetes with:

- external OIDC / Keycloak only
- Kubernetes `Ingress` resources instead of Traefik sidecars
- in-cluster PostgreSQL, RabbitMQ, and Redis
- optional `pgAdmin`

It intentionally does not deploy Keycloak.

## Layout

- `global.ingress` exposes the frontend, `shiftservice`, and `auditservice`
- `notificationIngress` handles `/notifications` separately because that service expects the prefix to be stripped
- `pgadmin.enabled=false` by default and no `pgAdmin` resources are created unless explicitly enabled

The default `notificationIngress` annotations target the NGINX ingress controller. If your cluster uses a different controller, update or replace that block in your values file.

## Required values

At minimum, set:

```yaml
global:
  domain: shiftcontrol.example.com
  oidc:
    baseUrl: https://auth.example.com
    realm: prod
    clientId: shiftcontrol
    issuerUri: https://auth.example.com/realms/prod
    tokenUrl: https://auth.example.com/realms/prod/protocol/openid-connect/token
  internalApiKey: change-me

postgres:
  auth:
    password: change-me

rabbitmq:
  auth:
    password: change-me
```

To enable email sending, also set:

```yaml
notificationservice:
  email:
    enableSending: true
    smtpHost: smtp.example.com
    smtpPort: 587
    smtpUsername: notifications@example.com
    smtpPassword: change-me
    fromName: ShiftControl Notifications
    fromEmail: noreply@example.com
    secureSocketOptions: StartTls
```

If you do not want Helm to create a secret, set `existingSecret` and provide these keys:

- `postgres-username`
- `postgres-password`
- `rabbitmq-username`
- `rabbitmq-password`
- `internal-api-key`
- `oidc-client-secret`
- `smtp-username`
- `smtp-password`
- `pgadmin-email`
- `pgadmin-password`

Database names stay in your values file even when `existingSecret` is used:

- `postgres.auth.database`
- `postgres.auth.notificationDatabase`

## Install

```bash
helm repo add shiftcontrol https://pilotwhale-os.github.io/ShiftControl
helm install shiftcontrol shiftcontrol/shiftcontrol -f my-values.yaml
```

You can start from [`values.prod.example.yaml`](./values.prod.example.yaml) and adjust secrets, storage, and ingress settings for your cluster.

If you expose notifications on a different hostname than `global.domain`, also set `notificationIngress.tls` for that host. The chart now validates that combination to avoid mismatched certificates.

For production deployments, pin application image tags instead of relying on the default `latest` tags in `values.yaml`.

## SMTP Behavior

The notification service source currently supports these email settings only:

- `Email__EnableSending`
- `Email__SmtpHost`
- `Email__SmtpPort`
- `Email__SmtpUsername`
- `Email__SmtpPassword`
- `Email__FromName`
- `Email__FromEmail`
- `Email__SecureSocketOptions`

`Email__SecureSocketOptions` accepts the MailKit enum names such as `None`, `Auto`, `SslOnConnect`, `StartTls`, and `StartTlsWhenAvailable`.

If your SMTP server does not require authentication, you can leave `smtpUsername` and `smtpPassword` empty.

## Publishing

The GitHub workflow in `.github/workflows/publish-helm-chart.yml` packages the chart and publishes it to the repository `gh-pages` branch using `chart-releaser`.

GitHub Pages should be configured to serve from the `gh-pages` branch for the repository URL above to work as a Helm repo.
