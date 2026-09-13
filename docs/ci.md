# CI/CD (GitHub Actions)

Workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

The pipeline builds the [Dockerfile](../Dockerfile), runs DevSecOps gates, and only then pushes a Docker image to a **private GitHub Container Registry** package: `ghcr.io/<owner>/<repo>`.

GHCR is used because a private GitHub repo gets a private package, and `GITHUB_TOKEN` is enough (`packages: write`). No Docker Hub password is stored.

## Job graph

```
version → sast → docker (build → Trivy → push)
```

`needs` ties the jobs together. If SAST fails, the image is not scanned as a release path and is **not** pushed. If Trivy fails on HIGH or CRITICAL, the push steps do not run. The scanned image is the deploy artifact; blocking the push blocks deployment.

| Event | Version bump | SAST + Trivy | Push to GHCR |
| --- | --- | --- | --- |
| PR to `main` or `dev` | No | Yes | No |
| Push to `dev` | No | Yes | `:dev` and `:<git-sha>` |
| Push to `main` | Patch (unless `[skip ci]`) | Yes | `:<semver>` and `:<git-sha>` |
| Actions → Run workflow on `main` | `patch` / `minor` / `major` | Yes | `:<semver>` and `:<git-sha>` |

Concurrency is per ref (in-progress runs cancel). Jobs have timeouts. Permissions are least-privilege: `contents: write` only on version, `packages: write` / `id-token` / `security-events` only on docker.

## Version bumping

On `main`, the workflow runs `npm version <bump> --no-git-tag-version`, then keeps Helm aligned:

- [`package.json`](../package.json) `version`
- [`helm/Chart.yaml`](../helm/Chart.yaml) `appVersion`
- [`helm/values.yaml`](../helm/values.yaml) `image.tag`

It commits `chore: bump version to X.Y.Z [skip ci]`, creates annotated tag `vX.Y.Z`, and pushes. `[skip ci]` plus GitHub’s rule that `GITHUB_TOKEN` pushes do not start a new workflow avoids bump loops.

PRs and `dev` keep the current `package.json` version. Image tags still include the git SHA (immutable).

## DevSecOps gates

**SAST (fail the pipeline on critical / ERROR)**

- **Semgrep** with `p/javascript` and `p/owasp-top-ten`, `--severity ERROR --error`. Semgrep’s highest severity is ERROR; that is treated as critical here.
- **npm audit --audit-level=critical** for known critical issues in npm dependencies (SCA).

**Image scan (fail the pipeline on high)**

- Build the image with Buildx (`load: true`) from the repo Dockerfile.
- **Trivy** (`HIGH,CRITICAL`, `exit-code: 1`). Findings are uploaded as SARIF to the repo **Security** tab.
- The workflow does **not** set `ignore-unfixed`. If `node:22-alpine` itself has HIGH CVEs, bump the base image (or add a tight `.trivyignore` only for a specific CVE you have accepted). Do not lower the exit code.

A failed SAST or Trivy job is the gate: no GHCR tags are published.

A green run means the image was built, scanned clean at those severities, and (on `main`/`dev` pushes) pushed with SBOM and provenance.

CI does not deploy. After a green push, **ArgoCD auto-sync** applies Helm from git. Follow [gitops.md](gitops.md) (Actions permissions, GHCR pull secret, `kubectl apply -n argocd -f argocd/`).

## Image and pipeline practices

Dockerfile: `NODE_ENV=production`, `npm ci --omit=dev --ignore-scripts`, non-root `USER node`, OCI labels, `HEALTHCHECK` on `/live`. `.dockerignore` keeps git, Helm, docs, and CI files out of the context.

Workflow: least-privilege permissions, no credential persistence on scan jobs, Helm lint, Semgrep in a pinned scanner image, Trivy HIGH/CRITICAL gate, GHCR push only after that, SBOM/provenance, GHA layer cache. In-progress runs cancel on pull requests only (not on `main`/`dev` pushes).

## GitHub settings

1. **Actions** → workflow permissions: allow read/write (needed to bump version and push packages).
2. **Packages**: after the first push, confirm the package is **private**. Grant `GITHUB_TOKEN` `packages: write` (already set on the docker job).
3. **Security** → Code scanning: Trivy SARIF appears after a scan (including failed scans, because upload uses `if: always()`).

Pull the image (after login):

```bash
echo "$CR_PAT" | docker login ghcr.io -u USER --password-stdin
docker pull ghcr.io/<owner>/<repo>:<tag>
```

Helm install against GHCR (cluster needs pull access; use an imagePullSecret if the package is private):

```bash
helm upgrade --install sample-nodejs ./helm \
  --set image.repository=ghcr.io/<owner>/<repo> \
  --set image.tag=<semver>
```

Production deploys should go through **ArgoCD**, not this command. See [gitops.md](gitops.md).
