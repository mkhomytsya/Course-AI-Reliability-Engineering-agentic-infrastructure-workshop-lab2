# a-box

Local Kubernetes environment using KinD, Flux CD, and kgateway (agentgateway). Gitless GitOps via OCI artifacts.

## Stack

- **KinD** — local Kubernetes cluster (1 control-plane + 2 workers)
- **Flux CD 2.x** — GitOps operator (Flux Operator + FluxInstance)
- **kgateway v2.3.0** — Kubernetes Gateway API implementation
- **kagent** — AI agent framework
- **cloud-provider-kind** — LoadBalancer support for KinD

## Quickstart

```bash
# In a GitHub Codespace or Linux machine:
make run
```

This installs OpenTofu and K9s, provisions the KinD cluster, bootstraps Flux, and starts cloud-provider-kind.

## How it works

```
make run  →  scripts/setup.sh
  → tofu apply (bootstrap/)
      → KinD cluster
      → helm: flux-operator
      → helm: flux-instance  (wait=true)
      → helm: flux-config       ← installs ResourceSetInputProvider + ResourceSet
          → RSIP polls oci://ghcr.io/den-vasyliev/a-box/releases (semver tags)
          → ResourceSet creates OCIRepository + Kustomization
              → releases/ OCI artifact reconciled:
                  kgateway-crds.yaml  → kgateway-crds HelmRelease (Gateway API CRDs)
                  kgateway.yaml       → kgateway HelmRelease (dependsOn crds)
                                      → GatewayClass + Gateway
                  kagent-crds.yaml    → kagent-crds HelmRelease
                  kagent.yaml         → kagent HelmRelease (dependsOn crds)
```

## CI/CD

Pushing to `main` (or tagging `v*`) triggers `.github/workflows/flux-push.yaml`:
- Pushes `releases/` as OCI artifact to `ghcr.io/den-vasyliev/a-box/releases`
- Packages and pushes `charts/flux-config` Helm chart to `ghcr.io/den-vasyliev/a-box`

RSIP picks up the new semver tag and Flux reconciles automatically — no git write-back.

## Directory Layout

| Path | Purpose |
|------|---------|
| `bootstrap/` | OpenTofu: KinD cluster + Flux bootstrap |
| `charts/flux-config/` | Helm chart: bootstraps RSIP + ResourceSet |
| `releases/` | OCI artifact contents: Flux manifests for kgateway + kagent |
| `scripts/setup.sh` | Full setup script (called by `make run`) |
| `.github/workflows/` | CI: push OCI artifact + Helm chart on merge |

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
