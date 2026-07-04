# ShiftControl

ShiftControl is a platform for planning and coordinating volunteers at conventions, conferences, and similar events.

This repository is the **overview and deployment repo**. It is the best starting point if you want to understand how the platform is split up, run the stack locally, or deploy it with Docker Compose or Helm.

## Start Here

Pick the path that matches what you need:

- **I want to understand the system at a glance**: start with [Repository Map](#repository-map) and [Service Map](#service-map)
- **I want to run ShiftControl locally**: see [compose/local/Readme.md](./compose/local/Readme.md)
- **I want to deploy with Docker Compose in production**: see [compose/prod/Readme.md](./compose/prod/Readme.md)
- **I want to deploy on Kubernetes**: see [charts/shiftcontrol/README.md](./charts/shiftcontrol/README.md)
- **I want to work on the frontend**: open [`shiftcontrol-frontend`](https://github.com/PilotWhale-OS/shiftcontrol-frontend)
- **I want to work on the Java backend services**: open [`shiftcontrol-java-backend`](https://github.com/PilotWhale-OS/shiftcontrol-java-backend)
- **I want to work on notifications / SignalR / email delivery**: open [`shiftcontrol-notificationservice`](https://github.com/PilotWhale-OS/shiftcontrol-notificationservice)

## What ShiftControl Does

ShiftControl helps planners create and operate volunteer shift plans while giving volunteers self-service tools such as sign-up, trading, auctions, and absence handling.

## Main Features

### For Planners

- create and manage shift plans per department or team
- define required positions, qualifications, and staffing needs
- invite volunteers with controlled invite links
- supervise assignment changes as the event gets closer
- approve or reject sensitive changes
- receive notifications about absences, emergencies, and important changes
- review audit history across the system
- get trust alerts about suspicious or abuse-prone behavior

### For Volunteers

- self-sign up for matching positions
- leave shifts when the current phase allows it
- trade assignments with other volunteers
- create auctions when they need someone else to take over
- define time constraints and availability limits
- trigger emergency absences when something unexpected happens
- receive web and email notifications

### Integrations And Platform Capabilities

- shift planning per department or team
- role and qualification-based assignments
- volunteer self-service workflows
- planner supervision and auditability
- notifications for user-facing changes
- synchronization with Pretalx event schedules
- centralized authentication through OIDC / Keycloak
- event-driven communication between services via RabbitMQ

## Repository Map

ShiftControl is split across multiple repositories on purpose. This repo ties them together.

| Repository | Purpose | Main Tech | Start Here |
| --- | --- | --- | --- |
| [`ShiftControl`](https://github.com/PilotWhale-OS/ShiftControl) | Overview, deployment assets, Helm chart, local/prod Compose stacks | YAML, Compose, Helm | [compose/local](./compose/local/Readme.md), [compose/prod](./compose/prod/Readme.md), [charts/shiftcontrol](./charts/shiftcontrol/README.md) |
| [`shiftcontrol-frontend`](https://github.com/PilotWhale-OS/shiftcontrol-frontend) | User-facing web app for planners and volunteers | Angular | [README](https://github.com/PilotWhale-OS/shiftcontrol-frontend/blob/main/README.md) |
| [`shiftcontrol-java-backend`](https://github.com/PilotWhale-OS/shiftcontrol-java-backend) | Core backend services and shared Java modules | Java, Spring Boot, Maven | [shiftservice README](https://github.com/PilotWhale-OS/shiftcontrol-java-backend/blob/main/shiftservice/README.md) |
| [`shiftcontrol-notificationservice`](https://github.com/PilotWhale-OS/shiftcontrol-notificationservice) | Notifications, SignalR push delivery, email sending, event-driven processing | C#, ASP.NET Core, SignalR | [README](https://github.com/PilotWhale-OS/shiftcontrol-notificationservice/blob/main/Readme.md) |

## Service Map

The runtime stack is made of several services with distinct responsibilities.

| Service / Module | Lives In | Responsibility |
| --- | --- | --- |
| `shiftcontrol-frontend` | `shiftcontrol-frontend` | Main web UI for planners and volunteers |
| `shiftservice` | `shiftcontrol-java-backend` | Core domain service for events, plans, shifts, assignments, roles, invite flows, and related APIs |
| `auditlog` / `auditservice` | `shiftcontrol-java-backend` | Persists and exposes audit/history data for changes across the platform |
| `trustservice` | `shiftcontrol-java-backend` | Evaluates event patterns and creates trust alerts for potentially abusive or risky volunteer behavior |
| `notificationservice` | `shiftcontrol-notificationservice` | Sends and delivers notifications via SignalR and email; consumes platform events |
| `pretalx-client` | `shiftcontrol-java-backend` | Generated and patched Java client used to integrate with Pretalx |
| `shiftcontrol-lib` | `shiftcontrol-java-backend` | Shared Java library for common contracts and event classes used across backend services |

## Deployment Map

This repo contains the deployment-facing entry points:

- [compose/local](./compose/local/Readme.md): local all-in-one stack for testing features quickly with preconfigured data and users
- [compose/prod](./compose/prod/Readme.md): production-oriented Docker Compose setup
- [charts/shiftcontrol](./charts/shiftcontrol/README.md): Kubernetes Helm chart

Current deployment shape in this repo:

- frontend and public APIs are exposed on one public app hostname
- `shiftservice`, `auditservice`, and `notificationservice` are routed behind path prefixes
- OIDC / Keycloak is part of the local stack, but production expects an external identity provider
- RabbitMQ is the event bus between services
- PostgreSQL stores service data
- Redis supports the trust service
- Traefik handles routing for Compose-based deployments

## How The Pieces Fit Together

At a high level:

1. The **frontend** authenticates users through OIDC / Keycloak and talks to backend APIs.
2. **shiftservice** owns the main planning and assignment domain.
3. Backend services publish and consume events over **RabbitMQ**.
4. **auditservice** records change history.
5. **trustservice** evaluates behavior patterns and raises alerts.
6. **notificationservice** turns events into user-visible notifications.

High-level architecture:

<img width="3378" height="1930" alt="ShiftControl Architecture" src="https://github.com/user-attachments/assets/44bd6c7d-a022-4859-a666-0fd239973048" />

## Common Newcomer Paths

If you are new to the project, these are usually the fastest entry points:

- **Product overview + local demo**: this repo, then [compose/local/Readme.md](./compose/local/Readme.md)
- **Frontend work**: [`shiftcontrol-frontend`](https://github.com/PilotWhale-OS/shiftcontrol-frontend)
- **Core backend work**: [`shiftcontrol-java-backend`](https://github.com/PilotWhale-OS/shiftcontrol-java-backend), especially [`shiftservice`](https://github.com/PilotWhale-OS/shiftcontrol-java-backend/tree/main/shiftservice)
- **Pretalx integration work**: [`pretalx-client`](https://github.com/PilotWhale-OS/shiftcontrol-java-backend/tree/main/pretalx-client)
- **Notifications work**: [`shiftcontrol-notificationservice`](https://github.com/PilotWhale-OS/shiftcontrol-notificationservice)
- **Kubernetes deployment work**: [charts/shiftcontrol](./charts/shiftcontrol/README.md)

## Project Status

The platform is actively being refactored from an older monolithic repository layout into clearer service-specific repositories and deployment assets.

That means:

- repository boundaries are getting cleaner
- service contracts are still evolving
- some modules are documented more deeply than others
- this repo should be treated as the umbrella entry point for newcomers
