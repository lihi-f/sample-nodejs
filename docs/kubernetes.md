# Kubernetes deployment (Helm)

`helm/` **is** the Helm chart for this app (`Chart.yaml` name: `sample-nodejs`). Install it with `helm upgrade --install sample-nodejs ./helm`.

This app is a small, **stateless** Express server. It serves HTTP routes, keeps Prometheus counters in memory, and does not use a database or disk. The port comes from `PORT` (default `8080`). Health endpoints already exist in the app:

| Probe | HTTP path | Purpose |
| --- | --- | --- |
| Readiness | `/ready` | Only send traffic when the process is up |
| Liveness | `/live` | Restart the container if the process hangs |

Main route: `GET /my-app`. Metrics: `GET /metrics`.

## Why a Deployment (not a StatefulSet)

Use a **Deployment**.

- Pods are interchangeable. Nothing depends on a stable hostname or start order.
- There is no persistent volume.
- Rolling updates and extra replicas are the natural way to run this.

A StatefulSet would add pod ordinals and volume templates this app does not need. If you later add a database or local disk, that **new** component can be a StatefulSet; this web app can stay a Deployment.

## Chart layout

```
helm/                    # chart root
  Chart.yaml             # name: sample-nodejs, type: application
  values.yaml
  .helmignore
  templates/
    _helpers.tpl
    deployment.yaml
    service.yaml
    ingress.yaml
    configmap.yaml
    secret.yaml          # off by default
    serviceaccount.yaml
    NOTES.txt
```

Defaults live in `values.yaml`. Change them there or with `--set` so the chart can grow without rewriting templates.

| Resource | Role |
| --- | --- |
| Deployment | Runs `replicaCount` pods, probes, resources |
| Service | ClusterIP: port 80 → container 8080 |
| Ingress | Host-based HTTP entry (nginx class by default) |
| ConfigMap | Non-secret env (`PORT`, `NODE_ENV`) |
| Secret | Optional; enable when you add keys later |
| ServiceAccount | Dedicated identity for the pods |

## Image

A [Dockerfile](../Dockerfile) at the repo root builds a Node 22 Alpine image that runs as the `node` user.

```bash
docker build -t sample-nodejs:1.0.0 .
# CI pushes to ghcr.io/<owner>/<repo>. Point the chart at that image:
# helm install ... --set image.repository=ghcr.io/<owner>/<repo> --set image.tag=1.0.0
```

## Install / upgrade

Needs a cluster (`kubectl`), Helm 3, and an Ingress controller if you leave `ingress.enabled: true`.

```bash
helm upgrade --install sample-nodejs ./helm \
  --set image.repository=sample-nodejs \
  --set image.tag=1.0.0
```

Useful overrides:

```bash
--set replicaCount=1
--set ingress.host=sample-nodejs.example.com
--set ingress.enabled=false
--set resources.limits.memory=512Mi
```

Enable a Secret later (the app does not read any secret today):

```yaml
secret:
  enabled: true
  data:
    EXAMPLE_API_KEY: change-me
```

Then `envFrom` on the Deployment loads those keys as environment variables.

## Check it

```bash
kubectl get pods,svc,ingress -l app.kubernetes.io/instance=sample-nodejs

kubectl port-forward svc/sample-nodejs 8080:80
curl http://127.0.0.1:8080/my-app
curl http://127.0.0.1:8080/ready
curl http://127.0.0.1:8080/live
curl http://127.0.0.1:8080/metrics
```

Uninstall:

```bash
helm uninstall sample-nodejs
```

## Growing later

Keep this chart small. Add pieces when you need them:

- **HPA** if load grows (CPU/memory on the existing requests).
- **TLS** on Ingress (`ingress.tls` in values).
- **Secrets** as above, or External Secrets, instead of putting keys in git.
- **HPA / PDB / NetworkPolicy** when the cluster and traffic justify them.
