# DevOps Sample Node.js App

## Layout

```
.
├── app/
│   ├── app.js
│   ├── package.json
│   └── Dockerfile
├── .github/workflows/ci.yml
├── helm/
├── argocd/
└── docs/
    ├── kubernetes.md
    ├── ci.md
    └── gitops.md
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

## CI/CD

Pull requests to `main` run tests and security checks. Successful `main` releases publish a private GHCR image, commit its immutable tag to Helm values, and create a SemVer Git tag. See [docs/ci.md](docs/ci.md).

Kubernetes deploys through **ArgoCD auto-sync** of the Helm chart in this repo (no deploy job in CI). See [docs/gitops.md](docs/gitops.md).

## Prerequisites

- Node.js (v22.1.0)
- Docker (to build the image)
- Kubernetes cluster and Helm 3 (to deploy)
