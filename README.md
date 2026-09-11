# DevOps Sample Node.js App

## Layout

```
.
├── app.js                 # Express app
├── package.json
├── Dockerfile             # image (build from repo root)
├── helm/                  # Helm chart for this app (Chart.yaml)
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
└── docs/
    └── kubernetes.md      # how and why we deploy
```

## Overview

A lightweight Node.js application. It features basic web endpoints, Prometheus metrics integration, and is designed for Kubernetes deployment and CI/CD pipeline demonstrations.

## Features

- Express.js web server
- Prometheus metrics integration
- Readiness and liveness probe endpoints
- Customizable port via environment variable

## Kubernetes

The app deploys with Helm as a **Deployment** (stateless HTTP service). See [docs/kubernetes.md](docs/kubernetes.md) for the chart, probes, Service, Ingress, resources, and ConfigMap/Secret usage.

## Prerequisites

- Node.js (v22.1.0)
- Docker (to build the image)
- Kubernetes cluster and Helm 3 (to deploy)
