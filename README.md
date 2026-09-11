# DevOps Sample Node.js App

## Layout

```
.
├── app.js
├── package.json
├── Dockerfile
├── .github/workflows/ci-cd.yml
├── helm/
└── docs/
    ├── kubernetes.md
    └── ci-cd.md
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

GitHub Actions bumps semver on `main`, runs Semgrep SAST and Trivy image scanning, then pushes to private GHCR only if those gates pass. See [docs/ci-cd.md](docs/ci-cd.md).

## Prerequisites

- Node.js (v22.1.0)
- Docker (to build the image)
- Kubernetes cluster and Helm 3 (to deploy)
