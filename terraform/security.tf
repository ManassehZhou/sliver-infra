# ─── Security group: cluster nodes / ECI pods ────────────────────────────────
#
# Traffic boundary:
#   Inbound:  only VPC-internal (SLB → Pod) and intra-group Pod traffic
#   Outbound: all allowed (Sliver outbound callback testing)
#   Direct Internet → Sliver: denied by default (public only reaches the
#   Redirector/SLB)

resource "alicloud_security_group" "cluster" {
  security_group_name = "${var.cluster_name}-sg"
  description = "Red team cluster SG - ECI pods / cluster nodes"
  vpc_id      = alicloud_vpc.main.id
  inner_access_policy = "Accept" # allow intra-group Pod traffic

  tags = local.common_tags
}

# ── Inbound: full VPC-internal access (SLB forwarding, Pod-to-Pod) ────────────

resource "alicloud_security_group_rule" "vpc_ingress" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 10
  security_group_id = alicloud_security_group.cluster.id
  cidr_ip           = var.vpc_cidr
}

# ── Inbound: public HTTPS/HTTP/DNS (ingress via the Redirector LoadBalancer) ──
# Note: these rules protect the Redirector Pod; the Sliver Pod has no public
# ingress and is isolated by NetworkPolicy.
# In a VPC, security group rules must use nic_type = "intranet" even for public
# CIDRs — public exposure is handled by the EIP/SLB, not the rule's nic_type.

resource "alicloud_security_group_rule" "public_https" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "443/443"
  priority          = 20
  security_group_id = alicloud_security_group.cluster.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "public_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 20
  security_group_id = alicloud_security_group.cluster.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "public_dns_udp" {
  type              = "ingress"
  ip_protocol       = "udp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "53/53"
  priority          = 20
  security_group_id = alicloud_security_group.cluster.id
  cidr_ip           = "0.0.0.0/0"
}

# ── Inbound: K8s API server (needed for kubectl port-forward) ────────────────

resource "alicloud_security_group_rule" "api_server" {
  for_each = toset(var.admin_cidrs)

  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "6443/6443"
  priority          = 15
  security_group_id = alicloud_security_group.cluster.id
  cidr_ip           = each.value
}

# ── Outbound: allow all (Sliver outbound C2 callbacks) ───────────────────────
# All VPC security group rules use nic_type = intranet; public egress is carried
# by the EIP/NAT, not by an "internet" rule type.

resource "alicloud_security_group_rule" "egress_all_intranet" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.cluster.id
  cidr_ip           = "0.0.0.0/0"
}
