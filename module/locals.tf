locals {
  # Currently support kops version
  supported_kops_version = "1.12.1"

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
  # Docker version can be looked up at https://github.com/kubernetes/kops/blob/master/nodeup/pkg/model/docker.go
  # Protokube hash changes only when the kops version changes.
  # Kubelet hash changes when the k8s version changes,
  # Kubectl hash changes when the k8s version changes.
  # CNI hash/filename change only when the major k8s version changes.
  # Easiest way to get new hashes is to create a dummy cluster using kops and
  # check user data.
  k8s_versions = {
    "1.12.9" = {
      kubelet_hash    = "e914b17532c411cb7c0cc472131b61935fb66b31"
      kubectl_hash    = "aa3e93897a6999d6c7dedbc41793c90d41eeb000"
      cni_hash        = "52e9d2de8a5f927307d9397308735658ee44ab8d"
      cni_file_name   = "cni-plugins-amd64-v0.7.5.tgz"
      utils_hash      = "ad4085c05ff02c241a38ff0033d76c699316f298"
      protokube_hash  = "175d2d9df2b9e317a40749a6d735577546a3c38d"
      docker_version  = "18.06.3"
      ami_name        = "k8s-1.12-debian-stretch-amd64-hvm-ebs-2019-05-14"
      ami_owner       = "383156758163"
      storage_backend = "etcd3"
      etcd_version    = "3.2.24"
    }

    "1.11.6" = {
      kubelet_hash    = "a006b4680640e5c88742e22b904623a77257f416"
      kubectl_hash    = "c3f7fbab5ba39e3ec20b32f0e7bcad6cc0704792"
      cni_hash        = "d595d3ded6499a64e8dac02466e2f5f2ce257c9f"
      cni_file_name   = "cni-plugins-amd64-v0.6.0.tgz"
      utils_hash      = "b16b5367e05bad082f416f786c7f8813f7794630"
      protokube_hash  = "725c2de47755544a9aa349e27ed9900d195f0ceb"
      docker_version  = "18.06.1"
      ami_name        = "k8s-1.11-debian-stretch-amd64-hvm-ebs-2018-08-17"
      ami_owner       = "383156758163"
      storage_backend = "etcd3"
      etcd_version    = "3.1.12"
    }

    "1.10.11" = {
      kubelet_hash    = "dbe06f92f4d1878482af0188070c6c0bca5d5e65"
      kubectl_hash    = "9ee2f78491cbf8dc76d644c23cfc8c955c34d55d"
      cni_hash        = "d595d3ded6499a64e8dac02466e2f5f2ce257c9f"
      cni_file_name   = "cni-plugins-amd64-v0.6.0.tgz"
      utils_hash      = "1903d30f87488f6e3550918283ff8aa1c5553471"
      protokube_hash  = "139d69230bb029a419ca8e5a9be2f406d8e685c4"
      docker_version  = "17.09.0"
      ami_name        = "k8s-1.10-debian-stretch-amd64-hvm-ebs-2018-08-17"
      ami_owner       = "383156758163"
      storage_backend = "etcd3"
      etcd_version    = "3.1.12"
    }

    "1.10.9" = {
      kubelet_hash    = "aadc25f7a7497d91419b168e4cb06e16755e8916"
      kubectl_hash    = "bf3914630fe45b4f9ec1bc5e56f10fb30047f958"
      cni_hash        = "d595d3ded6499a64e8dac02466e2f5f2ce257c9f"
      cni_file_name   = "cni-plugins-amd64-v0.6.0.tgz"
      utils_hash      = "1903d30f87488f6e3550918283ff8aa1c5553471"
      protokube_hash  = "139d69230bb029a419ca8e5a9be2f406d8e685c4"
      docker_version  = "17.09.0"
      ami_name        = "k8s-1.10-debian-stretch-amd64-hvm-ebs-2018-08-17"
      ami_owner       = "383156758163"
      storage_backend = "etcd3"
      etcd_version    = "3.1.12"
    }

    "1.9.8" = {
      kubelet_hash    = "6468397888494efe4a32e6bd96700ba6a86e635a"
      kubectl_hash    = "9a3537a7d95f1beec55e2fae082c364f6b91fdc0"
      cni_hash        = "d595d3ded6499a64e8dac02466e2f5f2ce257c9f"
      cni_file_name   = "cni-plugins-amd64-v0.6.0.tgz"
      utils_hash      = "72fac6679084d1f929d0abbd8a9ff9337273504b"
      protokube_hash  = "527db0b5fd4b635e6cb2ca22bfec813a048855a7"
      docker_version  = "1.13.1"
      ami_name        = "k8s-1.9-debian-jessie-amd64-hvm-ebs-2018-05-27"
      ami_owner       = "383156758163"
      storage_backend = "etcd2"
      etcd_version    = "2.2.1"
    }
  }
}

locals {
  k8s_settings = "${local.k8s_versions["${var.kubernetes_version}"]}"
}

locals {
  kubelet_hash    = "${local.k8s_settings["kubelet_hash"]}"
  kubectl_hash    = "${local.k8s_settings["kubectl_hash"]}"
  cni_hash        = "${local.k8s_settings["cni_hash"]}"
  cni_file_name   = "${local.k8s_settings["cni_file_name"]}"
  utils_hash      = "${local.k8s_settings["utils_hash"]}"
  protokube_hash  = "${local.k8s_settings["protokube_hash"]}"
  ami_name        = "${coalesce(var.override_ami_name, local.k8s_settings["ami_name"])}"
  ami_owner       = "${coalesce(var.override_ami_owner, local.k8s_settings["ami_owner"])}"
  docker_version  = "${local.k8s_settings["docker_version"]}"
  storage_backend = "${local.k8s_settings["storage_backend"]}"
  etcd_version    = "${local.k8s_settings["etcd_version"]}"
}

locals {
  has_spot_price   = "${var.max_price_spot == "" ? 0 : 1}"
  spot_enabled     = "${local.has_spot_price * var.enabled}"
  spot_asg_min     = "${var.spot_asg_min == "" ? var.node_asg_min : var.spot_asg_min}"
  spot_asg_max     = "${var.spot_asg_max == "" ? var.node_asg_max : var.spot_asg_max}"
  spot_asg_desired = "${var.spot_asg_desired == "" ? var.node_asg_desired : var.spot_asg_desired}"
}

locals {
  # Temporary variables due to the lack of combined logic operations.
  cluster_autoscaler_both          = "${var.node_cluster_autoscaling_type == "both" ? 1 : 0}"
  cluster_autoscaler_ondemand_only = "${var.node_cluster_autoscaling_type == "ondemand" ? 1 : 0}"
  cluster_autoscaler_spot_only     = "${var.node_cluster_autoscaling_type == "spot" ? 1 : 0}"

  # Either 'both' OR the type-specific autoscaler.
  # The reason this works is:
  # - signum(1 + 0) = 1 === true
  # - signum(1 + 1) = 1 === true
  # - signum(0 + 0) = 0 === false
  cluster_autoscaler_ondemand_enabled = "${signum(local.cluster_autoscaler_both + local.cluster_autoscaler_ondemand_only)}"

  cluster_autoscaler_spot_enabled = "${signum(local.cluster_autoscaler_both + local.cluster_autoscaler_spot_only)}"
}

locals {
  az_suspended_processes_raw = ["${var.asg_prevent_rebalance ? "AZRebalance" : ""}"]
  az_suspended_processes     = "${compact(local.az_suspended_processes_raw)}"
}
