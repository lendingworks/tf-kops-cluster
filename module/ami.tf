# We copy the AMI so we can (optionally) encrypt it if required.
resource "aws_ami_copy" "k8s-ami" {
  name              = "${local.ami_name}"
  description       = "An encrypted version of '${local.ami_name}'."
  source_ami_id     = "${data.aws_ami.k8s_ami.id}"
  source_ami_region = "${data.aws_region.current.name}"
  encrypted         = "${var.use_encryption}"

  tags {
    Name = "${data.aws_ami.k8s_ami.name}"
  }
}
