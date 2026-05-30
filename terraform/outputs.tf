output "cluster_id" {
  description = "ACS cluster ID"
  value       = alicloud_cs_managed_kubernetes.silver.id
}

output "nat_eip" {
  description = "NAT Gateway public IP (Sliver egress IP, can be allowlisted)"
  value       = alicloud_eip_address.nat.ip_address
}

output "vpc_id" {
  description = "VPC ID"
  value       = alicloud_vpc.main.id
}

output "cluster_security_group_id" {
  description = "Cluster security group ID"
  value       = alicloud_security_group.cluster.id
}

output "kubeconfig_path" {
  description = "Local kubeconfig path (written out, do not commit)"
  value       = "${path.root}/kubeconfig.yaml"
  sensitive   = true
}

output "next_steps" {
  description = "Post-deploy instructions"
  value       = <<-EOT
    # 1. Configure kubectl
    export KUBECONFIG=terraform/kubeconfig.yaml

    # 2. Deploy resources (namespace + sliver + netpol)
    kubectl apply -k k8s/

    # 3. Operator connects to Sliver (multiplayer)
    kubectl -n red-team port-forward svc/sliver 31337:31337

    # 4. Get the public C2 address (implant callbacks); configure
    #    http/https/dns listeners in the Sliver console to bind 80/443/53.
    kubectl -n red-team get svc sliver-c2 -o wide
  EOT
}
