variable instance_type {
  description = "EC2 node instance type"
  type        = string
  default     = "p3.2xlarge"
}

variable ecs_node_ami_id {
  description = "AMI ID of the base EC2 node instance"
  type        = string
  // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-ami-versions.html
  // aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended

  //  default = "ami-00a8f3b59eec913dc"
  default = ""
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_security_group" "worker_sg" {
  vpc_id = var.vpc_id

  name = "${var.cluster_name}-worker-sg"

  # Debug SSH
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = {
    Name      = "ECS ${var.cluster_name} for gpu worker"
    Terraform = true
  }

}


data "aws_iam_policy_document" "assume_role_worker_instance" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "spotfleet.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs-instance" {
  name               = "${var.cluster_name}-instance-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_worker_instance.json

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

resource "aws_iam_instance_profile" "ecs-instance" {
  name = "${var.cluster_name}-instance-profile"
  path = "/"
  role = aws_iam_role.ecs-instance.id
}

resource "aws_iam_role_policy_attachment" "spot_request_policy" {
  role       = aws_iam_role.ecs-instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}


data "aws_ami" "ecs_ami_cpu" {
  most_recent = true
  owners = [
    "amazon"
  ]

  filter {
    name = "owner-alias"
    values = [
      "amazon"
    ]
  }

  filter {
    name = "name"
    values = [
    "amzn-ami-*-amazon-ecs-optimized"]
  }
}

data "aws_ami" "ecs_ami_gpu" {
  most_recent = true
  owners = [
    "amazon"
  ]

  filter {
    name = "owner-alias"
    values = [
      "amazon"
    ]
  }

  filter {
    name = "name"
    values = [
    "amzn2-ami-ecs-gpu-hvm-*-x86_64-ebs"]
  }
}


variable "key_pair_name" {
  description = "aws_key_pair name for the EC2 instances"
  type        = string
}
