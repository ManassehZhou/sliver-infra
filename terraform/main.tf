# ─── Data sources ─────────────────────────────────────────────────────────────

data "alicloud_zones" "available" {
  available_resource_creation = "VSwitch"
}

# ─── VPC ─────────────────────────────────────────────────────────────────────

resource "alicloud_vpc" "main" {
  vpc_name    = "${var.cluster_name}-vpc"
  cidr_block  = var.vpc_cidr
  description = "Silver red-team VPC"

  tags = local.common_tags
}

# ─── VSwitch: private subnets (where cluster pods run) ────────────────────────

resource "alicloud_vswitch" "private_a" {
  vswitch_name = "${var.cluster_name}-private-a"
  vpc_id       = alicloud_vpc.main.id
  cidr_block   = cidrsubnet(var.vpc_cidr, 4, 0) # 10.10.0.0/20
  zone_id      = data.alicloud_zones.available.zones[0].id

  tags = local.common_tags
}

resource "alicloud_vswitch" "private_b" {
  vswitch_name = "${var.cluster_name}-private-b"
  vpc_id       = alicloud_vpc.main.id
  cidr_block   = cidrsubnet(var.vpc_cidr, 4, 1) # 10.10.16.0/20
  zone_id      = data.alicloud_zones.available.zones[1].id

  tags = local.common_tags
}

# ─── VSwitch: public subnet (NAT Gateway attachment point) ───────────────────

resource "alicloud_vswitch" "public" {
  vswitch_name = "${var.cluster_name}-public"
  vpc_id       = alicloud_vpc.main.id
  cidr_block   = cidrsubnet(var.vpc_cidr, 4, 15) # 10.10.240.0/20
  zone_id      = data.alicloud_zones.available.zones[0].id

  tags = local.common_tags
}

# ─── NAT Gateway (egress for cluster pods) ───────────────────────────────────

resource "alicloud_eip_address" "nat" {
  address_name         = "${var.cluster_name}-nat-eip"
  bandwidth            = tostring(var.nat_bandwidth)
  internet_charge_type = "PayByTraffic"
  payment_type         = "PayAsYouGo"

  tags = local.common_tags
}

resource "alicloud_nat_gateway" "main" {
  vpc_id           = alicloud_vpc.main.id
  nat_gateway_name = "${var.cluster_name}-nat"
  payment_type     = "PayAsYouGo"
  vswitch_id       = alicloud_vswitch.public.id
  nat_type         = "Enhanced"

  tags = local.common_tags
}

resource "alicloud_eip_association" "nat" {
  allocation_id = alicloud_eip_address.nat.id
  instance_id   = alicloud_nat_gateway.main.id
  instance_type = "Nat"
}

# SNAT: private subnets → NAT → Internet (Sliver outbound callbacks)
resource "alicloud_snat_entry" "private_a" {
  snat_table_id     = alicloud_nat_gateway.main.snat_table_ids
  source_vswitch_id = alicloud_vswitch.private_a.id
  snat_ip           = alicloud_eip_address.nat.ip_address
  snat_entry_name   = "${var.cluster_name}-snat-a"

  depends_on = [alicloud_eip_association.nat]
}

resource "alicloud_snat_entry" "private_b" {
  snat_table_id     = alicloud_nat_gateway.main.snat_table_ids
  source_vswitch_id = alicloud_vswitch.private_b.id
  snat_ip           = alicloud_eip_address.nat.ip_address
  snat_entry_name   = "${var.cluster_name}-snat-b"

  depends_on = [alicloud_eip_association.nat]
}

# ─── Locals ──────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    Project     = "silver"
    Environment = "red-team"
    ManagedBy   = "terraform"
  }
}
