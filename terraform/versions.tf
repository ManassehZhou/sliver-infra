terraform {
  required_version = ">= 1.5"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.230"
    }
  }

  # Recommended: enable remote state so sensitive outputs (kubeconfig, etc.)
  # are not stored locally.
  # backend "oss" {
  #   bucket   = "your-tfstate-bucket"
  #   prefix   = "silver/terraform.tfstate"
  #   region   = "cn-hangzhou"
  #   encrypt  = true
  # }
}

provider "alicloud" {
  region = var.region
  # Named credential profile (~/.aliyun/config.json). Leave empty to use
  # environment-variable credentials instead:
  #   export ALICLOUD_ACCESS_KEY="..."
  #   export ALICLOUD_SECRET_KEY="..."
  profile = var.credential_profile
}
