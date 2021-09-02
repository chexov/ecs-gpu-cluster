variable "valid_until" {
  description = "Spot fleet request is valid until this date"
  default     = "2033-01-01T01:00:00Z"
}

variable "spot_fleet_max_price" {
  type    = string
  default = "1.1"
}

variable "spot_fleet_target_capacity" {
  type    = number
  default = 0
}

resource "aws_spot_fleet_request" "ecs_spot_nodes" {

  lifecycle {
    ignore_changes = [
    target_capacity]
  }

  iam_fleet_role      = aws_iam_role.ecs-instance.arn
  allocation_strategy = "diversified"
  target_capacity     = var.spot_fleet_target_capacity
  valid_until         = var.valid_until
  fleet_type          = "maintain"

  terminate_instances_with_expiration = true
  replace_unhealthy_instances         = true
  excess_capacity_termination_policy  = "Default"
  //  spot_price = var.spot_fleet_max_price

  launch_specification {
    instance_type            = var.instance_type
    ami                      = var.ecs_node_ami_id == "" ? data.aws_ami.ecs_ami_gpu.id : var.ecs_node_ami_id
    iam_instance_profile_arn = aws_iam_instance_profile.ecs-instance.arn
    key_name                 = var.key_pair_name
    availability_zone        = var.availability_zone
    subnet_id                = var.subnet_id
    vpc_security_group_ids = [
      aws_security_group.worker_sg.id,
      var.security_group_id
    ]

    root_block_device {
      volume_type           = "standard"
      volume_size           = local.root_size_gb
      delete_on_termination = true
    }
    user_data = local.userdata

    tags = {
      Name      = "${var.cluster_name} ecs-spot-node"
      Terraform = true
    }
  }
}
