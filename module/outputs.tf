output "node_sg_id" {
  value = aws_security_group.node.id
}

# These outputs need to be lists as they use 'count' to determine if they
# will be created.
output "node_asg_names" {
  value = aws_autoscaling_group.node.*.name
}

output "node_asg_ids" {
  value = aws_autoscaling_group.node.*.id
}

output "node_asg_arns" {
  value = aws_autoscaling_group.node.*.arn
}

# These spot outputs need to be lists as they use 'count' to determine if they
# will be created.
output "node_spot_asg_names" {
  value = aws_autoscaling_group.node_spot.*.name
}

output "node_spot_asg_ids" {
  value = aws_autoscaling_group.node_spot.*.id
}

output "node_spot_asg_arns" {
  value = aws_autoscaling_group.node_spot.*.arn
}

output "master_sg_id" {
  value = aws_security_group.master.id
}

output "master_elb_sg_id" {
  value = aws_security_group.master_elb.id
}

output "master_elb_dns_name" {
  value = aws_elb.master.dns_name
}

output "master_asg_names" {
  value = aws_autoscaling_group.master.*.name
}

output "master_asg_ids" {
  value = aws_autoscaling_group.master.*.id
}

output "master_asg_arns" {
  value = aws_autoscaling_group.master.*.arn
}

output "nodes_additional_asg_names" {
  value = aws_autoscaling_group.nodes_additional.*.name
}

output "nodes_additional_asg_ids" {
  value = aws_autoscaling_group.nodes_additional.*.id
}

output "nodes_additional_asg_arns" {
  value = aws_autoscaling_group.nodes_additional.*.arn
}

output "all_asg_names" {
  value = concat(
    aws_autoscaling_group.master.*.name,
    aws_autoscaling_group.node.*.name,
    aws_autoscaling_group.node_spot.*.name,
    aws_autoscaling_group.nodes_additional.*.name,
  )
}

output "cluster_fqdn" {
  value = local.cluster_fqdn
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "masters_role_arn" {
  value = aws_iam_role.masters.arn
}

output "masters_role_name" {
  value = aws_iam_role.masters.name
}

output "nodes_role_arn" {
  value = aws_iam_role.nodes.arn
}

output "nodes_role_name" {
  value = aws_iam_role.nodes.name
}

output "master_azs" {
  value = local.master_azs
}

