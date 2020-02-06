locals {
  # Currently supported kops version
  supported_kops_version = "1.16.0-beta.1"

  # Removes the last character of the FQDN if it is '.'
  cluster_fqdn = replace(var.cluster_fqdn, "/\\.$/", "")

  # AZ names and letters are used in tags and resources names
  az_names       = sort(data.aws_availability_zones.available.names)
  az_letters_csv = replace(join(",", local.az_names), data.aws_region.current.name, "")
  az_letters     = split(",", local.az_letters_csv)

  # Number master resources to create. Defaults to the number of AZs in the region but should be 1 for regions with odd number of AZs.
  master_resource_count = var.force_single_master ? 1 : length(local.az_names)

  # Master AZs is used in the `kops create cluster` command
  master_azs = var.force_single_master ? element(local.az_names, 0) : join(",", local.az_names)

  # etcd AZs is used in tags for the master EBS volumes
  etcd_azs = var.force_single_master ? element(local.az_letters, 0) : local.az_letters_csv

  # Subnet IDs to be used by k8s ASGs
  k8s_subnet_ids = length(var.private_subnet_ids) == 0 ? join(",", aws_subnet.public.*.id) : join(",", var.private_subnet_ids)
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
    "1.16.6" = {
      kubelet_hash    = "47b99b6b9c4654a3fd5e3f093763429f8a6007f788bd7394bd0b85cb7ae4b2d0"
      kubectl_hash    = "05aae29c6e96fc07db195878263d3b625b623b9f16f87851e4a8ed8d234bcc2d"
      cni_hash        = "3ca15c0a18ee830520cf3a95408be826cbd255a1535a38e0be9608b25ad8bf64"
      cni_file_name   = "cni-plugins-amd64-v0.7.5.tgz"
      utils_hash      = "fef545b247951287c4509dcb606b4370f4241bfa94a6c0181c83eac2295856c7"
      protokube_hash  = "9453692c9de143353b1ae38e2dcb22524e131ddcdcf1b373be94876c87a437d1"
      docker_version  = "18.09.9"
      ami_name        = "k8s-1.16-debian-stretch-amd64-hvm-ebs-2020-01-17"
      ami_owner       = "383156758163"
      storage_backend = "etcd3"
      etcd_version    = "3.3.10"
    }
  }
}

locals {
  k8s_settings = local.k8s_versions[var.kubernetes_version]
}

locals {
  kubelet_hash    = local.k8s_settings["kubelet_hash"]
  kubectl_hash    = local.k8s_settings["kubectl_hash"]
  cni_hash        = local.k8s_settings["cni_hash"]
  cni_file_name   = local.k8s_settings["cni_file_name"]
  utils_hash      = local.k8s_settings["utils_hash"]
  protokube_hash  = local.k8s_settings["protokube_hash"]
  ami_name        = coalesce(var.override_ami_name, local.k8s_settings["ami_name"])
  ami_owner       = coalesce(var.override_ami_owner, local.k8s_settings["ami_owner"])
  docker_version  = local.k8s_settings["docker_version"]
  storage_backend = local.k8s_settings["storage_backend"]
  etcd_version    = local.k8s_settings["etcd_version"]
}

locals {
  default_nodes_enabled = var.enabled && var.node_asg_max > 0
  spot_enabled          = var.max_price_spot != "" && var.enabled
  spot_asg_min          = var.spot_asg_min == "" ? var.node_asg_min : var.spot_asg_min
  spot_asg_max          = var.spot_asg_max == "" ? var.node_asg_max : var.spot_asg_max
  spot_asg_desired      = var.spot_asg_desired == "" ? var.node_asg_desired : var.spot_asg_desired
}

locals {
  cluster_autoscaler_ondemand_enabled = var.node_cluster_autoscaling_type == "both" || var.node_cluster_autoscaling_type == "ondemand"
  cluster_autoscaler_spot_enabled     = var.node_cluster_autoscaling_type == "both" || var.node_cluster_autoscaling_type == "spot"
}

locals {
  az_suspended_processes_raw = [var.asg_prevent_rebalance ? "AZRebalance" : ""]
  az_suspended_processes     = compact(local.az_suspended_processes_raw)
}

