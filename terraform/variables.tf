variable "region" {
  description = "Alibaba Cloud region"
  type        = string
  default     = "cn-hangzhou"
}

variable "credential_profile" {
  description = "Named credential profile in ~/.aliyun/config.json. Leave empty to use ALICLOUD_ACCESS_KEY / ALICLOUD_SECRET_KEY env vars."
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "ACS cluster name (also used as the prefix for other resources)"
  type        = string
  default     = "silver-redteam"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "nat_bandwidth" {
  description = "NAT Gateway egress bandwidth (Mbps)"
  type        = number
  default     = 100
}

variable "admin_cidrs" {
  description = "Source CIDRs allowed to reach the K8s API server (tighten to operator IPs before go-live)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "public_api_endpoint" {
  description = "Whether to expose the K8s API publicly (required for kubectl port-forward)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Cluster deletion protection (recommended true in production)"
  type        = bool
  default     = false
}

variable "resource_group_id" {
  description = "Alibaba Cloud resource group ID (empty uses the default group)"
  type        = string
  default     = ""
}
