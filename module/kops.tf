resource "null_resource" "check_kops_version" {
  provisioner "local-exec" {
    command = "AWS_PROFILE=${var.aws_profile} kops version | grep -q ${local.supported_kops_version} || echo 'Unsupported kops version. Version ${local.supported_kops_version} must be used'"
  }
}

resource "null_resource" "create_cluster" {
  depends_on = ["null_resource.check_kops_version"]

  provisioner "local-exec" {
    command = "AWS_PROFILE=${var.aws_profile} kops create cluster --cloud=aws --dns ${var.kops_dns_mode} --authorization RBAC --networking ${var.kubernetes_networking} --zones=${join(",", data.aws_availability_zones.available.names)} --node-count=${var.node_asg_desired} --master-zones=${local.master_azs} --target=terraform --api-loadbalancer-type=public --vpc=${var.vpc_id} --state=s3://${var.kops_s3_bucket_id} --kubernetes-version ${var.kubernetes_version} ${local.cluster_fqdn}"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "AWS_PROFILE=${var.aws_profile} kops delete cluster --yes --state=s3://${var.kops_s3_bucket_id} --unregister ${local.cluster_fqdn}"
  }
}

resource "null_resource" "create_spot_instancegroup" {
  depends_on = ["null_resource.create_cluster"]

  provisioner "local-exec" {
    command = "AWS_PROFILE=${var.aws_profile} kops create ig nodes-spot --role=node --state=s3://${var.kops_s3_bucket_id} --output=yaml --name=${local.cluster_fqdn} --edit=false"
  }
}

resource "null_resource" "delete_tf_files" {
  depends_on = ["null_resource.create_cluster"]

  provisioner "local-exec" {
    command = "rm -rf out"
  }
}
