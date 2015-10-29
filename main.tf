/* Setup our aws provider */
provider "aws" {
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  region      = "${var.region}"
}
/* Autoscaling Group */
resource "template_file" "init" {
  filename = "${var.cloud_init}"
  vars {
    pup_fqdn = "${var.provisioner}"
    hostname = "asg-${var.hostname}"
    internal_domain = "${var.internal_domain}"
  }
}

resource "aws_launch_configuration" "asg_lc" {
  name = "${var.app_name}-lc"
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  user_data = "${template_file.init.rendered}"
  security_groups = ["${var.sg_private_id}"]
  key_name = ["${var.key_name}"]
}

resource "aws_autoscaling_policy" "asg" {
  name = "${var.app_name}-policy"
  scaling_adjustment = 2
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
}

resource "aws_autoscaling_group" "asg" {
  /* availability_zones = ["${aws_subnet.private.availability_zone}}"] */
  vpc_zone_identifier = ["${var.subnet_ids}"]
  name = "${var.app_name}-asg"
  max_size = "${var.max_size}"
  min_size = "${var.min_size}"
  health_check_grace_period = 300
  health_check_type = "ELB"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.asg_lc.name}"
  tag {
    key = "Name"
    value = "${var.hostname}"
    propagate_at_launch = true
  }
  load_balancers = ["${split(",", var.loadbalancer_ids)}"]
}
