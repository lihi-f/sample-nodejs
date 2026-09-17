# GitOps with ArgoCD

ArgoCD deploys one production application from the `main` branch of this repository. For this project I kept it small to make the assignment easy to inspect, a larger platform should move cluster configuration to a dedicated GitOps repository.

## Requirments

1. Install ArgoCD in the `argocd` namespace.
2. Create the namespace and private GHCR pull secret:

```bash
kubectl create namespace sample-nodejs
kubectl create secret docker-registry ghcr-pull \
  --namespace sample-nodejs \
  --docker-server=ghcr.io \
  --docker-username=USER_NAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=you@example.com
```

The PAT needs `read:packages`. If the repository itself is private, also add it to ArgoCD using a read-only credential.

3. Register the application:

```bash
kubectl apply -n argocd -f argocd/application.yaml
```

## Release and deployment flow

On a successful `main` release, CI pushes a private image and only then commits the immutable commit-SHA image tag to Helm values. ArgoCD watches `main`, renders `helm/` with `values.yaml` and `values-prod.yaml`, and automated sync applies that desired state to `sample-nodejs`.

Automated sync enables `prune` and `selfHeal`. `CreateNamespace=true` handles the initial namespace creation. CI does not access the cluster directly.

```text
main push → CI validate and scan → GHCR publish → GitOps commit
                                             ↓
                            ArgoCD auto-sync → Kubernetes pulls exact SHA image
```
