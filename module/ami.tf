# We copy the AMI so we can (optionally) encrypt it if required.
resource "aws_ami_copy" "k8s-ami" {
  name              = "${data.aws_ami.k8s_ami.name}"
  description       = "An encrypted version of '${data.aws_ami.k8s_ami.name}'."
  source_ami_id     = "${data.aws_ami.k8s_ami.id}"
  source_ami_region = "${data.aws_region.current.name}"
  encrypted         = "${var.use_encryption}"

  tags {
    Name = "${data.aws_ami.k8s_ami.name}"
  }
}
