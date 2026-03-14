# ==========================================
# Gateway API CRDs
# ==========================================
resource "helm_release" "gateway_api_crds" {
  depends_on       = [kind_cluster.this]
  name             = "gateway-api-crds"
  namespace        = "gateway-api-system"
  repository       = "oci://ghcr.io/den-vasyliev"
  chart            = "gateway-api-crds"
  version          = "1.4.0"
  create_namespace = true
}

# ==========================================
# Bootstrap Agentgateway
# ==========================================
resource "helm_release" "agentgateway_crds" {
  depends_on       = [helm_release.gateway_api_crds]
  name             = "agentgateway-crds"
  namespace        = "agentgateway-system"
  repository       = "oci://ghcr.io/kgateway-dev/charts"
  chart            = "kgateway-crds"
  version          = "2.3.0-main"
  create_namespace = true
}

resource "helm_release" "agentgateway" {
  depends_on       = [helm_release.agentgateway_crds]
  name             = "agentgateway"
  namespace        = "agentgateway-system"
  repository       = "oci://ghcr.io/kgateway-dev/charts"
  chart            = "kgateway"
  version          = "2.3.0-main"
  create_namespace = true
}
