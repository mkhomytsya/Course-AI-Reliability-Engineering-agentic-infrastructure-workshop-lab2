# ==========================================
# Construct k3d cluster
# ==========================================
resource "null_resource" "k3d_cluster" {
  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      k3d cluster create ${var.cluster_name} \
        --servers 1 \
        --agents 2 \
        -p "80:80@loadbalancer" \
        --k3s-arg '--disable=traefik@server:*'
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.triggers.cluster_name}"
  }
}
