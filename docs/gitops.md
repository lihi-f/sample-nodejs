# GitOps with ArgoCD

ArgoCD deploys this app from **this repository** (not a second GitOps repo). The Helm chart in [`helm/`](../helm/) is the desired state. GitHub Actions never talks to the cluster.

## Why the app repo, not a separate GitOps repo

| Option | When it fits |
| --- | --- |
| **This repo** (chosen) | One app, chart already here, CI already writes `image.tag` on `main` |
| Separate GitOps repo | Many apps, one ops team, app repos must not hold cluster config |

A second repo would only copy the same chart.

## Why auto-sync, not a CI deploy job

ArgoCD **automated sync** (prune + selfHeal) is the deployer:

- CI builds, scans, and pushes the image to GHCR.
- On `main`, CI also commits the new Helm `image.tag` (existing version job).
- ArgoCD watches `helm/` and applies the cluster when git changes.

There is no `kubectl apply`, `helm upgrade`, or `argocd app sync` stage in GitHub Actions. If ArgoCD syncs before GHCR has the new tag, the pod retries the pull until the image exists.

```
CI: version bump (helm tag) + SAST + Trivy + GHCR push
        ↓ git
ArgoCD auto-sync → Kubernetes  →  pull GHCR
```

## Bootstrap (once)

1. Install ArgoCD in the cluster (official install into namespace `argocd`).
2. Replace `OWNER/sample-nodejs` in [`argocd/application.yaml`](../argocd/application.yaml), [`argocd/application-dev.yaml`](../argocd/application-dev.yaml), [`helm/values-prod.yaml`](../helm/values-prod.yaml), and [`helm/values-dev.yaml`](../helm/values-dev.yaml).
3. If this GitHub repo is **private**, add it in ArgoCD (Settings → Repositories) with a read-only token.
4. Apply the Application CRs (not from CI):

```bash
kubectl apply -n argocd -f argocd/
```

| Application | Branch | Helm values | Namespace |
| --- | --- | --- | --- |
| `sample-nodejs` | `main` | `values.yaml` + `values-prod.yaml` | `sample-nodejs` |
| `sample-nodejs-dev` | `dev` | `values.yaml` + `values-dev.yaml` | `sample-nodejs-dev` |

Prod uses the semver tag from [`helm/values.yaml`](../helm/values.yaml) (updated by CI). Dev uses tag `dev` and `pullPolicy: Always` so a newly pushed `:dev` image is pulled.

## Private GHCR

Create a pull secret in each app namespace, then uncomment `imagePullSecrets` in the env values file:

```bash
kubectl create namespace sample-nodejs
kubectl create secret docker-registry ghcr-pull \
  --namespace sample-nodejs \
  --docker-server=ghcr.io \
  --docker-username=GITHUB_USER \
  --docker-password=GITHUB_TOKEN \
  --docker-email=you@example.com
```

The Deployment already mounts `imagePullSecrets` when that list is set.
