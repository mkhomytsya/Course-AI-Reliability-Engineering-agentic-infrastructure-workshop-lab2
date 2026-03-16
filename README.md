# abox

Local Kubernetes environment using KinD, Flux CD, and agentgateway. Gitless GitOps via OCI artifacts.

## Stack

- **KinD** — local Kubernetes cluster (1 control-plane + 2 workers)
- **Flux CD 2.x** — GitOps operator (Flux Operator + FluxInstance)
- **agentgateway v2.2.1** — Kubernetes Gateway API implementation
- **kagent** — AI agent framework
- **cloud-provider-kind** — LoadBalancer support for KinD

## Quickstart

```bash
make run
```

Installs OpenTofu and K9s, provisions the KinD cluster, bootstraps Flux, starts cloud-provider-kind.

## How it works

```
make run  →  scripts/setup.sh
  → tofu apply (bootstrap/)
      → KinD cluster
      → helm: flux-operator
      → helm: flux-instance        (wait=true)
      → kubectl_manifest: RSIP     (depends_on flux-instance)
          polls oci://ghcr.io/den-vasyliev/abox/releases
          filter: semver tags only  ^\d+\.\d+\.\d+$
      → kubectl_manifest: ResourceSet  (depends_on RSIP)
          creates OCIRepository + 2 Kustomizations per tag
              → releases/crds/ reconciled first:
                  gateway-api-crds.yaml   → gateway-api-crds HelmRelease
                  agentgateway-crds.yaml  → agentgateway-crds HelmRelease
                  kagent-crds.yaml        → kagent-crds HelmRelease
              → releases/ reconciled after crds:
                  agentgateway.yaml  → agentgateway HelmRelease + Gateway
                  kagent.yaml        → kagent HelmRelease + HTTPRoute
```

## Releasing

```bash
make push
```

Bumps patch version, tags, and pushes to trigger CI. The CI workflow publishes `releases/` as an OCI artifact. RSIP picks it up and Flux reconciles automatically.

## Directory Layout

| Path | Purpose |
|------|---------|
| `bootstrap/` | OpenTofu: KinD cluster + Flux bootstrap (operator, instance, RSIP, ResourceSet) |
| `releases/crds/` | CRDs: gateway-api, agentgateway, kagent |
| `releases/` | agentgateway + kagent Flux manifests |
| `scripts/setup.sh` | Full setup script (called by `make run`) |
| `.github/workflows/flux-push.yaml` | CI: push `releases/` as OCI artifact on `v*` tags |

## Verify

```bash
# Flux resources
flux get all

# Gateway
kubectl get gateway,httproute -A
kubectl get gatewayclass agentgateway

# LoadBalancer IP
kubectl get svc -n agentgateway-system

# kagent
kubectl get agents -n kagent
```
