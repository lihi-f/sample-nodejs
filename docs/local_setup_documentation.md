# Local Development & Deployment Setup

This document outlines the local setup used for demonstrating our CI/CD pipeline, Kubernetes cluster, and GitOps workflow. 

> **Important Note:** This setup is designed purely for simple local demonstrations and rapid testing. It is **not** intended for production environments and does not follow advanced production security best practices.

---

## Architecture Overview

The end-to-end flow involves the following components:

1. **Source Control & CI (GitHub):** Code changes are pushed to a GitHub repository. A GitHub Actions workflow automatically builds the container image and pushes it to a private GitHub Container Registry (`GHCR`).
2. **Local Kubernetes Cluster (Docker Desktop):** A local Kubernetes cluster runs via Docker Desktop, equipped with an Ingress controller and ArgoCD.
3. **GitOps Deployment (ArgoCD):** ArgoCD synchronizes the application state. For demo simplicity, the application manifest and the private registry pull secret are deployed manually.
4. **Local DNS Resolution:** Windows hosts file is manually modified to route the custom ingress domain to the local cluster.

---

## Demo Video

Watch the video below to see the complete deployment workflow in action:

<video controls width="100%">
  <source src="../media/Demo - Sample Nodejs.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>
