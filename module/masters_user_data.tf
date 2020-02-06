data "template_file" "master_user_data_1" {
  count    = local.master_resource_count
  template = file("${path.module}/user_data/01_nodeup_url.sh.tpl")

  vars = {
    kops_version = local.supported_kops_version
    aws_region   = data.aws_region.current.name
  }
}

data "template_file" "master_user_data_3" {
  count    = local.master_resource_count
  template = file("${path.module}/user_data/03_master_cluster_spec.sh.tpl")

  vars = {
    kubernetes_version = var.kubernetes_version
    master_count       = local.master_resource_count
    cluster_fqdn       = local.cluster_fqdn
    docker_version     = local.docker_version
    etcd_version       = local.etcd_version
    storage_backend    = local.storage_backend
  }
}

data "template_file" "master_user_data_4" {
  count    = local.master_resource_count
  template = file("${path.module}/user_data/04_ig_spec.sh.tpl")

  vars = {
    instance_group = "master-${element(local.az_names, count.index)}"
    taints         = "null"
  }
}

data "template_file" "master_user_data_5" {
  count    = local.master_resource_count
  template = file("${path.module}/user_data/05_kube_env.sh.tpl")

  vars = {
    kubernetes_version    = var.kubernetes_version
    kops_version          = local.supported_kops_version
    cluster_fqdn          = local.cluster_fqdn
    kops_s3_bucket        = var.kops_s3_bucket_id
    kubernetes_master_tag = "- _kubernetes_master"
    etcd_manifests        = <<MANIFEST
etcdManifests:
- s3://${var.kops_s3_bucket_id}/${local.cluster_fqdn}/manifests/etcd/main.yaml
- s3://${var.kops_s3_bucket_id}/${local.cluster_fqdn}/manifests/etcd/events.yaml
MANIFEST

    instance_group = "master-${element(local.az_names, count.index)}"
    kubelet_hash   = local.kubelet_hash
    kubectl_hash   = local.kubectl_hash
    cni_hash       = local.cni_hash
    cni_file_name  = local.cni_file_name
    utils_hash     = local.utils_hash
    protokube_hash = local.protokube_hash
  }
}

