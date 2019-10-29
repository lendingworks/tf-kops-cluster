locals {
  node_subnet_ids = split(",", local.k8s_subnet_ids)
}

### ASG OnDemand Instances
resource "aws_autoscaling_group" "node" {
  count                = var.enabled ? 1 : 0
  depends_on           = [null_resource.create_cluster]
  name                 = "nodes.${var.cluster_fqdn}"
  launch_configuration = aws_launch_configuration.node[0].id
  max_size             = var.node_asg_max
  min_size             = var.enabled ? var.node_asg_min : 0
  desired_capacity     = var.enabled ? var.node_asg_desired : 0
  vpc_zone_identifier  = local.node_subnet_ids
  target_group_arns    = var.node_alb_ingress_target_group_arns
  suspended_processes  = local.az_suspended_processes

  # Ignore changes to autoscaling group desired as it is managed by the
  # Kubernetes cluster autoscaler addon
  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "KubernetesCluster"
    value               = local.cluster_fqdn
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "nodes.${var.cluster_fqdn}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "nodes"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.cluster_autoscaler_ondemand_enabled ? "enabled" : "disabled"}"
    value               = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/custom-ondemandworker"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "node" {
  count                = var.enabled ? 1 : 0
  name_prefix          = "k8s-${var.cluster_name}-node-"
  image_id             = aws_ami_copy.k8s-ami.id
  instance_type        = var.node_instance_type
  key_name             = var.instance_key_name
  iam_instance_profile = aws_iam_instance_profile.nodes.name
  user_data            = "${element(data.template_file.node_user_data_1.*.rendered, count.index)}${file("${path.module}/user_data/02_download_nodeup.sh")}${element(data.template_file.node_user_data_3.*.rendered, count.index)}${element(data.template_file.node_user_data_4.*.rendered, count.index)}${element(data.template_file.node_user_data_5.*.rendered, count.index)}"

  security_groups = [
    aws_security_group.node.id,
    var.sg_allow_ssh,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.node_volume_size
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node" {
  name        = "nodes.${var.cluster_fqdn}"
  vpc_id      = var.vpc_id
  description = "Kubernetes cluster ${var.cluster_name} nodes"

  tags = {
    "Name"                                      = "nodes.${var.cluster_fqdn}"
    "KubernetesCluster"                         = local.cluster_fqdn
    "kubernetes.io/cluster/${var.cluster_fqdn}" = "owned"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### If max_price_spot, then will be created one more ASG and LC
resource "aws_autoscaling_group" "node_spot" {
  count = local.spot_enabled ? 1 : 0

  depends_on           = [null_resource.create_spot_instancegroup]
  name                 = "nodes-spot.${var.cluster_fqdn}"
  launch_configuration = aws_launch_configuration.node_spot[0].id
  max_size             = local.spot_asg_max
  min_size             = var.enabled ? local.spot_asg_min : 0
  desired_capacity     = var.enabled ? local.spot_asg_desired : 0
  vpc_zone_identifier  = local.node_subnet_ids
  target_group_arns    = var.node_alb_ingress_target_group_arns
  suspended_processes  = local.az_suspended_processes

  # Ignore changes to autoscaling group desired as it is managed by the
  # Kubernetes cluster autoscaler addon
  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "KubernetesCluster"
    value               = local.cluster_fqdn
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "nodes-spot.${var.cluster_fqdn}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "nodes-spot"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.cluster_autoscaler_spot_enabled ? "enabled" : "disabled"}"
    value               = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/custom-spotworker"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "node_spot" {
  count = local.spot_enabled ? 1 : 0

  name_prefix          = "k8s-${var.cluster_name}-node-spot-"
  image_id             = aws_ami_copy.k8s-ami.id
  instance_type        = var.spot_node_instance_type
  key_name             = var.instance_key_name
  spot_price           = var.max_price_spot
  iam_instance_profile = aws_iam_instance_profile.nodes.name
  user_data = "${element(data.template_file.node_user_data_1.*.rendered, count.index)}${file("${path.module}/user_data/02_download_nodeup.sh")}${element(data.template_file.node_user_data_3.*.rendered, count.index)}${element(
    data.template_file.node_user_data_4_spot.*.rendered,
    count.index,
    )}${element(
    data.template_file.node_user_data_5_spot.*.rendered,
    count.index,
  )}"

  security_groups = [
    aws_security_group.node.id,
    var.sg_allow_ssh,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.node_volume_size
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nodes_additional" {
  count                = length(var.additional_instance_groups)
  depends_on           = [null_resource.create_additional_instancegroups]
  name                 = "${var.additional_instance_groups[count.index].name}.${var.cluster_fqdn}"
  launch_configuration = aws_launch_configuration.nodes_additional[count.index].id
  max_size             = var.additional_instance_groups[count.index].capacity_max
  min_size             = var.additional_instance_groups[count.index].capacity_min
  desired_capacity     = var.additional_instance_groups[count.index].capacity_desired
  vpc_zone_identifier  = length(var.additional_instance_groups[count.index].subnet_ids) == 0 ? local.node_subnet_ids : var.additional_instance_groups[count.index].subnet_ids
  target_group_arns    = var.node_alb_ingress_target_group_arns
  suspended_processes  = local.az_suspended_processes

  # Ignore changes to desired capacity as it is managed by the  Kubernetes
  # cluster autoscaler.
  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "KubernetesCluster"
    value               = local.cluster_fqdn
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.additional_instance_groups[count.index].name}.${var.cluster_fqdn}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = var.additional_instance_groups[count.index].name
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.cluster_autoscaler_spot_enabled ? "enabled" : "disabled"}"
    value               = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/custom-spotworker"
    value               = var.additional_instance_groups[count.index].max_spot_price == "" ? "false" : "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.additional_instance_groups[count.index].tags
    content {
      key                 = tag.value.name
      value               = tag.value.value
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_configuration" "nodes_additional" {
  count                = length(var.additional_instance_groups)
  name_prefix          = "k8s-${var.cluster_name}-${var.additional_instance_groups[count.index].name}-"
  image_id             = aws_ami_copy.k8s-ami.id
  instance_type        = var.additional_instance_groups[count.index].instance_type
  key_name             = var.instance_key_name
  spot_price           = var.additional_instance_groups[count.index].max_spot_price == "" ? null : var.additional_instance_groups[count.index].max_spot_price
  iam_instance_profile = aws_iam_instance_profile.nodes.name
  ebs_optimized        = var.additional_instance_groups[count.index].ebs_optimised
  user_data = "${element(data.template_file.node_user_data_1.*.rendered, count.index)}${file("${path.module}/user_data/02_download_nodeup.sh")}${element(data.template_file.node_user_data_3.*.rendered, count.index)}${element(
    data.template_file.node_user_data_4_additional.*.rendered,
    count.index,
    )}${element(
    data.template_file.node_user_data_5_additional.*.rendered,
    count.index,
  )}"

  security_groups = [
    aws_security_group.node.id,
    var.sg_allow_ssh,
  ]

  root_block_device {
    volume_type           = var.additional_instance_groups[count.index].root_volume_type
    iops                  = var.additional_instance_groups[count.index].root_volume_type == "io1" ? var.additional_instance_groups[count.index].root_volume_iops : null
    volume_size           = var.additional_instance_groups[count.index].root_volume_size
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
