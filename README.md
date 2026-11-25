# g10f Helm charts

Helm charts for the g10f applications, published at https://g10f.github.io/helm-charts.

| Chart        | Application                                                                     |
|--------------|---------------------------------------------------------------------------------|
| `sso`        | [G10F Single Sign-On](https://github.com/g10f/sso): backend, messaging worker, media nginx, migration job, CronJobs |
| `django-app` | Generic Django application (e.g. the OIDC client demo), optional media nginx    |
| `wiki`       | Wiki with persistent storage, nginx in front of gunicorn                        |

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add g10f https://g10f.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages. You can then run `helm search repo g10f` to see the charts.

To install the sso chart:

    helm install my-sso g10f/sso

To uninstall the chart:

    helm uninstall my-sso

The available settings and their defaults are documented in each chart's `values.yaml`.

## Pinning a version

Every chart version has a release and a git tag `<chart>-<version>`, e.g. `sso-1.4.0`. Install a fixed version with
`helm install my-sso g10f/sso --version 1.4.0`. When the chart is used straight from git (e.g. an Argo CD application
with `path: charts/sso`), set `targetRevision` to the tag: without it the deployment follows `main`, and every merge
is rolled out at once.

## Running the sso chart with Pod Security `restricted`

The backend, the messaging worker, the migration job and the CronJobs take `podSecurityContext` and
`securityContext`; the media nginx has its own settings under `media`. Since the default `nginx` image runs as root,
use an unprivileged image on port 8080 there:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
media:
  image:
    repository: nginxinc/nginx-unprivileged
    tag: <version>
  containerPort: 8080
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 101
    seccompProfile:
      type: RuntimeDefault
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop: [ALL]
```

The CronJob pods carry the label `app.kubernetes.io/name: <chart name>-job` (not the backend's selector labels), so a
NetworkPolicy can select them separately.

## Releasing a chart

1. Change the chart and raise `version` in its `Chart.yaml` (and `appVersion` when the default image changes).
2. Merge or push to `main`. The workflow `.github/workflows/release.yml` runs
   [chart-releaser](https://github.com/helm/chart-releaser-action): it packages every chart whose version has no
   release yet, creates the release and tag `<chart>-<version>` and updates the repository index on `gh-pages`.

A chart that changed without a version bump is not published: chart-releaser skips the existing version, and the
workflow shows a warning for it.
