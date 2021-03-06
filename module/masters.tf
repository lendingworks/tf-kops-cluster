resource "aws_autoscaling_group" "master" {
  depends_on           = [null_resource.create_cluster]
  count                = local.master_resource_count
  name                 = "master-${element(local.az_names, count.index)}.masters.${var.cluster_fqdn}"
  vpc_zone_identifier  = [element(split(",", local.k8s_subnet_ids), count.index)]
  launch_configuration = element(aws_launch_configuration.master.*.id, count.index)
  load_balancers       = [aws_elb.master.name]
  max_size             = 1
  min_size             = var.enabled ? 1 : 0
  desired_capacity     = var.enabled ? 1 : 0

  tag {
    key                 = "KubernetesCluster"
    value               = local.cluster_fqdn
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "master-${element(local.az_names, count.index)}.masters.${var.cluster_fqdn}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "master-${element(local.az_names, count.index)}"
    propagate_at_launch = true
  }
}

resource "aws_elb" "master" {
  name         = "k8s-${var.cluster_name}-master"
  subnets      = aws_subnet.public.*.id
  idle_timeout = 1200

  security_groups = [
    aws_security_group.master_elb.id,
    var.sg_allow_http_s,
  ]

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:443"
    interval            = 30
  }

  tags = {
    Name              = "api.${var.cluster_fqdn}"
    KubernetesCluster = local.cluster_fqdn
  }
}

resource "aws_route53_record" "master_elb" {
  name = "api.${local.cluster_fqdn}"
  type = "A"

  alias {
    name                   = aws_elb.master.dns_name
    zone_id                = aws_elb.master.zone_id
    evaluate_target_health = false
  }

  zone_id = "/hostedzone/${var.route53_zone_id}"
}

resource "aws_security_group" "master" {
  name        = "master.${var.cluster_fqdn}"
  vpc_id      = var.vpc_id
  description = "K8s ${var.cluster_name} masters"

  tags = {
    "Name"                                      = "master.${var.cluster_fqdn}"
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

resource "aws_security_group_rule" "master_elb_to_master" {
  type                     = "ingress"
  security_group_id        = aws_security_group.master.id
  source_security_group_id = aws_security_group.master_elb.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}

resource "aws_security_group" "master_elb" {
  name        = "api-elb.${var.cluster_fqdn}"
  vpc_id      = var.vpc_id
  description = "K8s ${var.cluster_name} master ELB"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                      = "api-elb.${var.cluster_fqdn}"
    "KubernetesCluster"                         = local.cluster_fqdn
    "kubernetes.io/cluster/${var.cluster_fqdn}" = "owned"
  }
}

resource "aws_launch_configuration" "master" {
  count                = local.master_resource_count
  name_prefix          = "k8s-${var.cluster_name}-master-${element(local.az_names, count.index)}-"
  image_id             = aws_ami_copy.k8s-ami.id
  instance_type        = var.master_instance_type
  key_name             = var.instance_key_name
  iam_instance_profile = aws_iam_instance_profile.masters.name
  user_data = "${element(
    data.template_file.master_user_data_1.*.rendered,
    count.index,
    )}${file("${path.module}/user_data/02_download_nodeup.sh")}${element(
    data.template_file.master_user_data_3.*.rendered,
    count.index,
    )}${element(
    data.template_file.master_user_data_4.*.rendered,
    count.index,
    )}${element(
    data.template_file.master_user_data_5.*.rendered,
    count.index,
  )}"

  security_groups = [
    aws_security_group.master.id,
    var.sg_allow_ssh,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 64
    delete_on_termination = true
  }

  ephemeral_block_device {
    device_name  = "/dev/sdc"
    virtual_name = "ephemeral0"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ebs_volume" "etcd-events" {
  count             = local.master_resource_count
  availability_zone = element(local.az_names, count.index)
  size              = 20
  type              = var.etcd_volume_type
  iops              = var.etcd_volume_piops
  encrypted         = var.use_encryption

  tags = {
    "KubernetesCluster"                         = local.cluster_fqdn
    "Name"                                      = "${element(local.az_letters, count.index)}.etcd-events.${local.cluster_fqdn}"
    "k8s.io/etcd/events"                        = "${element(local.az_letters, count.index)}/${local.etcd_azs}"
    "k8s.io/role/master"                        = "1"
    "kubernetes.io/cluster/${var.cluster_fqdn}" = "owned"
  }
}

resource "aws_ebs_volume" "etcd-main" {
  count             = local.master_resource_count
  availability_zone = element(local.az_names, count.index)
  size              = 20
  type              = var.etcd_volume_type
  iops              = var.etcd_volume_piops
  encrypted         = var.use_encryption

  tags = {
    "KubernetesCluster"                         = local.cluster_fqdn
    "Name"                                      = "${element(local.az_letters, count.index)}.etcd-main.${local.cluster_fqdn}"
    "k8s.io/etcd/main"                          = "${element(local.az_letters, count.index)}/${local.etcd_azs}"
    "k8s.io/role/master"                        = "1"
    "kubernetes.io/cluster/${var.cluster_fqdn}" = "owned"
  }
}

resource "aws_cloudwatch_metric_alarm" "master_cpu" {
  count               = local.master_resource_count
  alarm_name          = "k8s_${var.cluster_name}_${element(local.az_names, count.index)}_masters_k8s_cpu"
  alarm_description   = "K8s masters cluster CPU utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.master_k8s_cpu_threshold

  dimensions = {
    AutoScalingGroupName = element(aws_autoscaling_group.master.*.name, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "ebs-wiops-etcd-events" {
  count               = local.master_resource_count
  alarm_name          = "k8s_${var.cluster_name}_${element(local.az_names, count.index)}_etcd_events_ebs_write_IOPS"
  alarm_description   = "Etcd Events EBS WriteOps"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "VolumeWriteOps"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.etcd_volume_piops * 300

  dimensions = {
    VolumeId = element(aws_ebs_volume.etcd-events.*.id, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "ebs-vqlength-etcd-events" {
  count               = local.master_resource_count
  alarm_name          = "k8s_${var.cluster_name}_${element(local.az_names, count.index)}_etcd_events_ebs_queue_length"
  alarm_description   = "Etcd Events EBS Volume Queue Length"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "VolumeQueueLength"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Sum"
  threshold           = 5000

  dimensions = {
    VolumeId = element(aws_ebs_volume.etcd-events.*.id, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "ebs-riops-etcd-events" {
  count               = local.master_resource_count
  alarm_name          = "k8s_${var.cluster_name}_${element(local.az_names, count.index)}_etcd_events_ebs_read_IOPS"
  alarm_description   = "Etcd Events EBS ReadOps"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "VolumeReadOps"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Sum"
  threshold           = 10

  dimensions = {
    VolumeId = element(aws_ebs_volume.etcd-events.*.id, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "ebs-wiops-etcd-main" {
  count               = local.master_resource_count
  alarm_name          = "k8s_${var.cluster_name}_${element(local.az_names, count.index)}_etcd_main_ebs_write_IOPS"
  alarm_description   = "Etcd Main EBS WriteOps"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "VolumeWriteOps"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.etcd_volume_piops * 300

  dimensions = {
    VolumeId = element(aws_ebs_volume.etcd-main.*.id, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "ebs-vqlength-etcd-mains" {
  count               = local.master_resource_count
  alarm_name          = "k8s_${var.cluster_name}_${element(local.az_names, count.index)}_etcd_main_ebs_queue_length"
  alarm_description   = "Etcd Main EBS Volume Queue Length"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "VolumeQueueLength"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    VolumeId = element(aws_ebs_volume.etcd-main.*.id, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "ebs-riops-etcd-main" {
  count               = local.master_resource_count
  alarm_name          = "k8s_${var.cluster_name}_${element(local.az_names, count.index)}_etcd_main_ebs_read_IOPS"
  alarm_description   = "Etcd Main EBS ReadOps"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "VolumeReadOps"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Sum"
  threshold           = 10

  dimensions = {
    VolumeId = element(aws_ebs_volume.etcd-main.*.id, count.index)
  }
}

