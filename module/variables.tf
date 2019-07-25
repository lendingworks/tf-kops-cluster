# If FALSE, this will scale the cluster down to zero instances but keep all
# volumes so that it can be brought back up.
variable "enabled" {
  default = true
}

# Name for the cluster
variable "cluster_name" {
}

# Fully qualified DNS name of cluster
variable "cluster_fqdn" {
}

# ID of the VPC
variable "vpc_id" {
}

# Route53 zone ID
variable "route53_zone_id" {
}

# ARN of the kops bucket
variable "kops_s3_bucket_arn" {
}

# ID of the kops bucket
variable "kops_s3_bucket_id" {
}

# Name of the SSH key to use for cluster nodes and master
variable "instance_key_name" {
}

# Security group ID to allow SSH from. Nodes and masters are added to this security group
variable "sg_allow_ssh" {
}

# Security group ID to allow HTTP/S from. Master ELB is added to this security group
variable "sg_allow_http_s" {
}

# ID of internet gateway for the VPC
variable "internet_gateway_id" {
}

variable "aws_profile" {
}

# A list of CIDR subnet blocks to use for Kubernetes public subnets. Should be 1 per AZ.
variable "public_subnet_cidr_blocks" {
  type = list(string)
}

# Use encryption for all volumes.
variable "use_encryption" {
  default = false
}

# Force single master. Can be used when a master per AZ is not required or if running
# in a region with only 2 AZs.
variable "force_single_master" {
  default = false
}

# Instance type for the master
variable "master_instance_type" {
  default = "m3.medium"
}

# Instance type for nodes
variable "node_instance_type" {
  default = "t2.medium"
}

# Spot node instance type
variable "spot_node_instance_type" {
  default = "t2.medium"
}

# Node autoscaling group min
variable "node_asg_min" {
  default = 2
}

# Node autoscaling group desired
variable "node_asg_desired" {
  default = 2
}

# Node autoscaling group max
variable "node_asg_max" {
  default = 2
}

# Size of each node's root disk
variable "node_volume_size" {
  default = 128
}

# Any ingress ALB target groups that need to be linked to the nodes
variable "node_alb_ingress_target_group_arns" {
  type    = list(string)
  default = []
}

# One of 'disabled', 'ondemand', 'spot' or 'both'.
variable "node_cluster_autoscaling_type" {
  type    = string
  default = "disabled"
}

# Spot instance price, default is null
variable "max_price_spot" {
  default = ""
}

# Spot instance min, if not set - will use the ondemand instance min.
variable "spot_asg_min" {
  default = ""
}

# Spot instance desired, if not set - will use the ondemand instance desired.
variable "spot_asg_desired" {
  default = ""
}

# Spot instance max, if not set - will use the ondemand instance max.
variable "spot_asg_max" {
  default = ""
}

# Kubernetes version tag to use
variable "kubernetes_version" {
  default = "1.12.9"
}

# List of private subnet IDs. Pass 1 per AZ or if left blank then public subnets will be used
variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

# kops DNS mode
variable "kops_dns_mode" {
  default = "public"
}

# kops networking mode to use. Values other than flannel and calico are untested
variable "kubernetes_networking" {
  default = "calico"
}

# Cloudwatch alarm CPU
variable "master_k8s_cpu_threshold" {
  default = 80
}

# Override AMI.
variable "override_ami_name" {
  default = ""
}

# Override AMI owner.
variable "override_ami_owner" {
  default = ""
}

# Volume type for the etcd vols.
variable "etcd_volume_type" {
  default = "gp2"
}

# Provisioned IOPS for the etcd vols, only used if 'etcd_volume_type' is 'io1'.
variable "etcd_volume_piops" {
  default = 30
}

# If TRUE, this will prevent the ASG from re-balancing itself across regions.
variable "asg_prevent_rebalance" {
  default = false
}

