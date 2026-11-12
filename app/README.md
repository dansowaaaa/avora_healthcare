# Avora — Healthcare, within reach

A polished, responsive, **functional demo** of a fictional healthcare appointment platform. Built as an application starter for an AWS/Terraform cloud engineering project.

## Run locally

Open `index.html` in a browser. No build step or dependencies required. An optional local web server can be used for development (for example, VS Code Live Server). The Google Fonts import needs an internet connection; system fonts are used otherwise.

## What works

- Overview dashboard with live counts
- Searchable directory of 14 fictional healthcare professionals (doctors, nursing, physiotherapy, nutrition, and pharmacy), specialty filtering
- Appointment booking with date/time availability and prevention of double-booking in the same browser
- Appointment rescheduling and cancellation
- Upcoming, past, and cancelled appointment lists
- Personal demo notes (add and delete)
- Responsive desktop/mobile navigation
- Browser persistence using localStorage

## Limitations and safety

**Demo only.** All clinicians, clinics, ratings and schedules are fictional. No real booking is created and no secure medical records are maintained. Do not enter real medical or personally identifying data. The demo patient is Alex Asante; the avatar and name are placeholders. Data is stored only in the browser and can be cleared with local storage. Different browsers/devices do not share data. There is no real authentication, server-side validation, database, or access control in this first prototype.

For a live, public-facing deployment, we must add and test a secure backend, protected authentication, per-user authorization, rate limiting, audit logging, accessibility verification, and safeguards against double booking across users. Do not present this demo as a real healthcare service.

## Planned AWS deployment

We'll design a Terraform-managed environment with VPC, subnets, routing, security groups, EC2-based application services, monitoring and (where the cost budget supports it) high availability through a load balancer and Auto Scaling. Architecture and costs must be reviewed before any billable resource is deployed. The first demo can be previewed locally independently of AWS.

## Project files

- `index.html` — semantic page shell and navigation
- `styles.css` — responsive UI styling
- `app.js` — provider directory, booking flows and local state
