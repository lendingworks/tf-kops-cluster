locals {
  # Currently support kops version
  supported_kops_version = "1.9.2"

  # Removes the last character of the FQDN if it is '.'
  cluster_fqdn = "${replace(var.cluster_fqdn, "/\\.$/", "")}"

  # AZ names and letters are used in tags and resources names
  az_names       = "${sort(data.aws_availability_zones.available.names)}"
  az_letters_csv = "${replace(join(",", local.az_names), data.aws_region.current.name, "")}"
  az_letters     = "${split(",", local.az_letters_csv)}"

  # Number master resources to create. Defaults to the number of AZs in the region but should be 1 for regions with odd number of AZs.
  master_resource_count = "${var.force_single_master == 1 ? 1 : length(local.az_names)}"

  # Master AZs is used in the `kops create cluster` command
  master_azs = "${var.force_single_master == 1 ? element(local.az_names, 0) : join(",", local.az_names)}"

  # etcd AZs is used in tags for the master EBS volumes
  etcd_azs = "${var.force_single_master == 1 ? element(local.az_letters, 0) : local.az_letters_csv}"

  # Subnet IDs to be used by k8s ASGs
  k8s_subnet_ids = "${length(var.private_subnet_ids) == 0 ? join(",", aws_subnet.public.*.id) : join(",", var.private_subnet_ids)}"
}

locals {
  k8s_versions = {
    "1.9.8" = {
      kubelet_hash   = "6468397888494efe4a32e6bd96700ba6a86e635a"
      kubectl_hash   = "9a3537a7d95f1beec55e2fae082c364f6b91fdc0"
      cni_hash       = "d595d3ded6499a64e8dac02466e2f5f2ce257c9f"
      cni_file_name  = "cni-plugins-amd64-v0.6.0.tgz"
      utils_hash     = "72fac6679084d1f929d0abbd8a9ff9337273504b"
      protokube_hash = "527db0b5fd4b635e6cb2ca22bfec813a048855a7"
      ami_name       = "k8s-1.9-debian-jessie-amd64-hvm-ebs-2018-05-27"
      docker_version = "1.13.1"
    }
  }
}

locals {
  k8s_settings = "${local.k8s_versions["${var.kubernetes_version}"]}"
}

locals {
  kubelet_hash   = "${local.k8s_settings["kubelet_hash"]}"
  kubectl_hash   = "${local.k8s_settings["kubectl_hash"]}"
  cni_hash       = "${local.k8s_settings["cni_hash"]}"
  cni_file_name  = "${local.k8s_settings["cni_file_name"]}"
  utils_hash     = "${local.k8s_settings["utils_hash"]}"
  protokube_hash = "${local.k8s_settings["protokube_hash"]}"
  ami_name       = "${local.k8s_settings["ami_name"]}"
  docker_version = "${local.k8s_settings["docker_version"]}"
}

locals {
  # Temporary variables due to the lack of combined logic operations.
  cluster_autoscaler_both          = "${var.node_cluster_autoscaling_type == "both" ? 1 : 0}"
  cluster_autoscaler_ondemand_only = "${var.node_cluster_autoscaling_type == "ondemand" ? 1 : 0}"
  cluster_autoscaler_spot_only     = "${var.node_cluster_autoscaling_type == "spot" ? 1 : 0}"

  # Either 'both' OR the type-specific autoscaler.
  # The reason this works is because booleans are '1' or '0' in TF.
  # Thus, signum(1 + 0) = 1 === true and signum(1 + 1) = 1 === true.
  cluster_autoscaler_ondemand_enabled = "${signum(local.cluster_autoscaler_both + local.cluster_autoscaler_ondemand_only)}"

  cluster_autoscaler_spot_enabled = "${signum(local.cluster_autoscaler_both + local.cluster_autoscaler_spot_only)}"
}
