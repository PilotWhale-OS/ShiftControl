

# ShiftControl

ShiftControl is a platform for planning and coordinating volunteers at conventions, conferences and similar large events.

It enables planners to create shift structures, while giving volunteers modern **self-service capabilities** such as sign-ups, trades, auctions and absence handling.

The system is built using **event-driven microservices** and integrates with **Pretalx** for schedule synchronization and **Keycloak** for identity management.

## Features

### For Planners

* Create and manage shift plans per department
* Define required positions & qualifications
* Invite volunteers via configurable invite links
* Supervise assignments close to the event
* Approve or reject changes
* Get notified about absences & emergencies
* Full audit trail of all changes+
* Receive trust alerts about suspicious or abuse-prone behavior

### For Volunteers

* Self-signup for matching positions
* Leave shifts (depending on phase)
* Trade or auction assignments
* Configure time constraints
* Trigger emergency absences
* Receive notifications via mail & web

### Integration

* Continuous sync of events & activities from Pretalx
* Centralized identity via Keycloak
* REST + WebSocket APIs
* Event-driven communication via RabbitMQ


## Domain Overview

### Event

The convention or conference that is being organized.

### Activity

A scheduled item (panel, talk, workshop, meetup, …).
Activities can either be created manually or synced from Pretalx.
Synced activities are read-only.

### Shift

Represents work that needs to be done during a time range.
A shift can be linked to an activity or a location.

### PositionSlot

A specific role within a shift.

It defines:

* how many volunteers are required
* which role (qualification) is necessary
* a description of the task

### Role

Qualifications of volunteers (e.g. Medic, Stage Tech, Security).

### ShiftPlan

Groups shifts into departments (e.g. Stage, Security, Logistics).

Each plan has separate permissions and invite links.


## 🔄 Workflow

### 1. Event Setup

An administrator either:

* creates an event manually, or
* connects Pretalx via API key → events & activities are synced continuously.


### 2. Create Plans

Planners create shift plans per department.

Each plan provides **invite links** which can:

* grant planner or volunteer permissions
* have limited uses
* expire after a certain time


### 3. Create Shifts

Planners define:

* time
* activity or location
* required position slots
* qualifications


### 4. Volunteer Self-Service

Volunteers can sign themselves into positions **if they match the required roles**.


## Assignment Phases

### Self Signup

* Volunteers may freely join and leave.
* Ideal for early planning.

### Supervised

* Position counts cannot change without approval.
* Volunteers may:

  * trade positions
  * create auctions (request someone else to take over)

### Locked

* Any modification requires planner approval.


## Absence Management

### Time Constraints

Volunteers can define known unavailability (e.g., arriving later).

### Emergency Absence

If something unexpected happens:

* conflicting shifts are **automatically auctioned**
* planners receive notifications immediately


## Notifications

The system informs users via:

* web notifications
* email
* (WIP) messaging integrations like Telegram

No assignment change happens silently.


## Audit Log

Administrators can trace **every change** across the system for accountability and debugging.


## 🎤 Pretalx Integration

ShiftControl can connect to any Pretalx instance.

Required:

* Host URL
* API key

The system imports all events accessible by that key.
Activities remain synchronized and read-only.

## Trust & Abuse Prevention

ShiftControl heavily relies on volunteer self-service.  
To prevent misuse while still enabling flexibility, the system continuously evaluates user actions.

The **Trust Service** observes events such as:

- frequent late cancellations  
- repeated emergency absences  
- unusual trading or auction patterns  
- other behavior that may impact planning reliability  

If predefined thresholds or heuristics are triggered, the system generates a **trust alert**.

### What happens then?

Planners are notified and can:

- review the situation  
- contact the volunteer  
- deny future requests  
- or simply keep an eye on the assignments  

Trust alerts are **decision aids**, not automatic punishments.

The goal is to balance:

- volunteer autonomy  
- fairness  
- operational reliability

# Architecture

ShiftControl follows **event-driven design** and separates responsibilities into independent services.

Main goals:

* scalability
* loose coupling
* replaceability
* technology independence
* easier future extensions

### Core Principles

- asynchronous communication
- database per service
- API first
- IdP independence


### Services

* **shiftservice** → core planning & assignments
* **trustservice** → abuse detection via trust alerts
* **auditservice** → system history
* **notificationservice** → user notifications
* **telegram-bot (WIP)** → external messaging
* **frontend (Angular)**
* **Keycloak** → identity provider
* **Traefik** → routing / ingress
* **RabbitMQ** → event bus

### Repository scheme
- [ShiftControl Frontend](https://github.com/PilotWhale-OS/shiftcontrol-frontend)
- [Java Backend Services](https://github.com/PilotWhale-OS/shiftcontrol-java-backend)
  - shiftservice
  - auditservice
  - trustservice
  - pretalx-sync
- [Notification Service](https://github.com/PilotWhale-OS/shiftcontrol-notificationservice)

### High Level Architecture

<img width="3378" height="1930" alt="ShiftControl Architecture excalidraw" src="https://github.com/user-attachments/assets/44bd6c7d-a022-4859-a666-0fd239973048" />


## Identity & Authentication

All user information is managed centrally in Keycloak.

Services store only:

```
userId
```

Names, mail addresses, roles, etc. are resolved via the Keycloak API.

Advantages:

* no duplication
* no inconsistency
* flexible authentication methods (OAuth, OIDC, social login, …)

Backend communication uses JWT tokens.


## Technology Stack

| Area         | Technology         |
| ------------ | ------------------ |
| Backend      | Java / Spring Boot & C# |
| Frontend     | Angular            |
| Messaging    | RabbitMQ           |
| Notifications| SignalR in C#      |
| Auth         | Keycloak           |
| Ingress      | Traefik            |
| API          | REST + WebSocket   |
| Architecture | Event-Driven       |


## Project Status

⚠ The project is currently under heavy refactoring.

We are in the process of:

* splitting services into dedicated repositories
* cleaning boundaries
* improving event contracts
* preparing containerized deployments

Docker Compose files and installation guides will follow.


## Vision

ShiftControl aims to become a modern, flexible and extensible volunteer coordination platform that reduces organizational overhead while empowering communities.
