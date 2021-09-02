resource "aws_launch_configuration" "gpu-ecs-node" {
  name_prefix = "${var.cluster_name} ecs-ec2-node"
  # us-east-1. ecs optimized ami
  image_id = var.ecs_node_ami_id == "" ? data.aws_ami.ecs_ami_gpu.id : var.ecs_node_ami_id

  associate_public_ip_address = "true"
  key_name                    = var.key_pair_name
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ecs-instance.id

  root_block_device {
    volume_type           = "standard"
    volume_size           = local.root_size_gb
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups = [
    aws_security_group.worker_sg.id,
    var.security_group_id
  ]

  user_data = local.userdata
}

variable "asg_desired_capacity" {
  type    = number
  default = 0
}

variable "asg_max_size" {
  default = 1
}


resource "aws_autoscaling_group" "worker-autoscale" {
  lifecycle {
    ignore_changes = [
    desired_capacity]
  }
  name              = "${var.cluster_name}-ecs-workers"
  desired_capacity  = var.asg_desired_capacity
  health_check_type = "EC2"
  max_size          = var.asg_max_size
  min_size          = 0

  launch_configuration = aws_launch_configuration.gpu-ecs-node.name
  vpc_zone_identifier = [
  var.subnet_id]

  availability_zones = [
  var.availability_zone]

  tag {
    propagate_at_launch = true
    key                 = "Name"
    value               = "${var.cluster_name} ecs-ec2-node"
  }

  tag {
    propagate_at_launch = true
    key                 = "Terraform"
    value               = true
  }
}

