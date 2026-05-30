# ─── ACS cluster (Container Compute Service, Serverless) ─────────────────────
#
# Why ACS instead of ACK managed + virtual node:
#   On an ACK managed cluster the system components (coredns / csi-provisioner /
#   metrics-server / CCM) run as Deployments on real ECS nodes. With no node
#   pool they all stay Pending, so DNS, dynamic disks and SLB are unavailable.
#   ACS (the successor to ASK, which stopped accepting new clusters on
#   2025-02-17) is truly serverless: system components are managed by the
#   platform (managed-coredns / managed-csiprovisioner), no nodes required.
#
# profile = "Acs" creates an ACS cluster.

resource "alicloud_cs_managed_kubernetes" "silver" {
  name         = var.cluster_name
  profile      = "Acs"
  cluster_spec = "ack.pro.small"

  # vSwitches for the control plane / pod ENIs
  vswitch_ids = [
    alicloud_vswitch.private_a.id,
    alicloud_vswitch.private_b.id,
  ]

  service_cidr = "172.21.0.0/20"

  # Reuse our own VPC / NAT instead of letting ACK create another one.
  # Note: ACS clusters expose a public API endpoint by default; access is
  #       restricted by the security group api_server rule (6443 + admin_cidrs).
  new_nat_gateway = false

  security_group_id   = alicloud_security_group.cluster.id
  deletion_protection = var.deletion_protection

  resource_group_id = var.resource_group_id != "" ? var.resource_group_id : null

  tags = local.common_tags

  depends_on = [
    alicloud_snat_entry.private_a,
    alicloud_snat_entry.private_b,
  ]
}

# ─── kubeconfig ───────────────────────────────────────────────────────────────

data "alicloud_cs_cluster_credential" "silver" {
  cluster_id                 = alicloud_cs_managed_kubernetes.silver.id
  temporary_duration_minutes = 0
  output_file                = "${path.root}/kubeconfig.yaml"
}
