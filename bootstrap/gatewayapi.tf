# ==========================================
# Flux HelmRepository + HelmReleases
# (installs Gateway API CRDs + agentgateway)
# ==========================================
data "kubectl_file_documents" "helmreleases" {
  content = file("${path.module}/../gatewayapi/HelmReleases.yaml")
}

resource "kubectl_manifest" "helmreleases" {
  depends_on = [helm_release.flux_instance]
  for_each   = data.kubectl_file_documents.helmreleases.manifests

  yaml_body         = each.value
  server_side_apply = true
}
