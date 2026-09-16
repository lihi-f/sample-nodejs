# CI/CD

Workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

`main` is the only release branch. Pull requests targeting `main` are validated no matter which development branch they come from. Development branches do not publish images or deploy applications.

## Pipeline flow

```
detect changes
  ├─ test ──────────────┐
  ├─ dependency audit ──┼─ build and Trivy scan ─ publish image ─ update GitOps state
  ├─ Semgrep SAST ──────┘
  └─ Helm lint/template validation
```

Application changes run unit tests, `npm audit` (critical findings fail), Semgrep SAST (ERROR findings fail), a Docker build, and a Trivy image scan (HIGH and CRITICAL findings fail). Helm or ArgoCD changes run Helm lint and render validation. A pull request never pushes an image or changes GitOps state.

The Docker image is multi-stage: npm is used only in the Node 22 builder to install production dependencies, while the final image is the non-root distroless Node 22 runtime. This prevents npm and its bundled packages from being shipped or scanned in production. Both CI builds use `pull: true` so security updates to the base images are not hidden by the build cache.

After all application gates pass on `main`, CI publishes the private GHCR image with two tags:

- `:<semver>` is the human-readable release tag.
- `:<commit-sha>` is the immutable deployment tag.

CI then commits the next SemVer package/chart version and updates `helm/values.yaml` to the commit-SHA image tag. ArgoCD sees that commit and deploys the exact image that passed CI. The workflow creates the matching annotated Git tag. The default release is a patch bump, and a manual workflow run on `main` can choose minor or major.

GitHub Actions builds and verifies, ArgoCD reconciles the committed Helm desired state.

## Registry and permissions

GHCR remains private. The publish job has only `packages: write`, the final GitOps-update job has only `contents: write`. All other jobs use the workflow's read-only default. Kubernetes requires the `ghcr-pull` image pull secret described in [GitOps setup](gitops.md).
