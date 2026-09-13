# GitOps with ArgoCD

ArgoCD deploys one production application from the `main` branch of this repository. Keeping the Helm chart with this single service makes the assignment easy to inspect; a larger platform can move cluster configuration to a dedicated GitOps repository.

## Setup

1. Install ArgoCD in the `argocd` namespace.
2. Create the production namespace and private GHCR pull secret:

```bash
kubectl create namespace sample-nodejs
kubectl create secret docker-registry ghcr-pull \
  --namespace sample-nodejs \
  --docker-server=ghcr.io \
  --docker-username=lihi-f \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=you@example.com
```

The PAT needs `read:packages`. If the repository itself is private, also add it to ArgoCD using a read-only credential.

3. Register the application once:

```bash
kubectl apply -n argocd -f argocd/application.yaml
```

If you previously registered the development application, remove it once:

```bash
kubectl -n argocd delete application sample-nodejs-dev
```

## Release and deployment flow

On a successful `main` release, CI pushes a private image and only then commits the immutable commit-SHA image tag to Helm values. ArgoCD watches `main`, renders `helm/` with `values.yaml` and `values-prod.yaml`, and automated sync applies that desired state to `sample-nodejs`.

Automated sync enables `prune` and `selfHeal`; `CreateNamespace=true` handles the initial namespace creation. CI does not access the cluster directly.

```text
main push → CI validate and scan → GHCR publish → GitOps commit
                                             ↓
                            ArgoCD auto-sync → Kubernetes pulls exact SHA image
```

Check the result:

```bash
kubectl -n argocd get applications
kubectl -n sample-nodejs get pods,svc,ingress
```
