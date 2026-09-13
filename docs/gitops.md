# GitOps with ArgoCD

ArgoCD deploys this app from this repository to simplify the depolyment, for production use I would store the argocd manifest in a different repository. 

## What you need to do (in order)

Repo URL is already `https://github.com/lihi-f/sample-nodejs.git`. Image is `ghcr.io/lihi-f/sample-nodejs`.

1. **GitHub Actions**
   - Settings → Actions → General → Workflow permissions: **Read and write**.
   - Push to `dev` or `main` and wait until CI is green and a package exists under **Packages** (`ghcr.io/lihi-f/sample-nodejs`). Confirm it is **private**.

2. **Kubernetes + ArgoCD**
   - Have a cluster (`kubectl` works).
   - Install ArgoCD into namespace `argocd` (official install).
   - If the GitHub repo is private: ArgoCD UI → Settings → Repositories → add `https://github.com/lihi-f/sample-nodejs.git` with a read-only PAT (`repo` scope).

3. **GHCR pull secret** (private image)

```bash
kubectl create namespace sample-nodejs
kubectl create namespace sample-nodejs-dev

# PAT with read:packages (and SSO authorized if the org requires it)
kubectl create secret docker-registry ghcr-pull \
  --namespace sample-nodejs \
  --docker-server=ghcr.io \
  --docker-username=lihi-f \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=you@example.com

kubectl create secret docker-registry ghcr-pull \
  --namespace sample-nodejs-dev \
  --docker-server=ghcr.io \
  --docker-username=lihi-f \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=you@example.com
```

Helm overlays already reference `imagePullSecrets: [ghcr-pull]`.

4. **Register the apps once** (not from CI)

```bash
kubectl apply -n argocd -f argocd/
```

5. **Check**

```bash
kubectl -n argocd get applications
# UI: port-forward svc/argocd-server -n argocd 8080:443
kubectl -n sample-nodejs get pods,svc,ingress
kubectl -n sample-nodejs-dev get pods
```

After that, every green CI run on `main` updates Helm `image.tag` and ArgoCD auto-syncs. On `dev`, CI pushes `:dev` and ArgoCD uses `pullPolicy: Always`.

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

| Application | Branch | Helm values | Namespace |
| --- | --- | --- | --- |
| `sample-nodejs` | `main` | `values.yaml` + `values-prod.yaml` | `sample-nodejs` |
| `sample-nodejs-dev` | `dev` | `values.yaml` + `values-dev.yaml` | `sample-nodejs-dev` |
