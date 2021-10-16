resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.name}-ecs-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = var.name
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = "${var.name}-service-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "batch.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "compute" {
  compute_environment_name = var.name

  compute_resources {
    instance_role = aws_iam_instance_profile.ecs_instance_role.arn
    instance_type = [
      var.instance_type,
    ]

    type      = "EC2"
    max_vcpus = 16
    min_vcpus = 0

    security_group_ids = var.security_group_ids
    subnets            = var.subnets

  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"
  depends_on = [
    aws_iam_role_policy_attachment.aws_batch_service_role
  ]
}


locals {
  initial_env = [
    //    {
    //      name : "DEBUG",
    //      value : "False"
    //    },
  ]

  container_env = concat(local.initial_env, var.worker_env)

  container_properties = jsonencode({
    image : var.ecr_image,
    essential : true,
    logConfiguration : {
      logDriver : "awslogs"
    }
  })
}


resource "aws_batch_job_definition" "jobdef" {
  name = var.name
  type = "container"

  container_properties = <<CONTAINER_PROPERTIES
{
    "essential": true,
    "command": ${jsonencode(var.worker_command)},
    "image": "${var.ecr_image}",
    "memory": ${var.worker_memory_mb},
    "vcpus": 1,
    "environment": ${jsonencode(local.container_env)},
    "volumes": [
      {
        "host": {
          "sourcePath": "/tmp"
        },
        "name": "tmp"
      }
    ],
    "mountPoints": [
        {
          "sourceVolume": "tmp",
          "containerPath": "/tmp",
          "readOnly": false
        }
    ],
    "ulimits": [
      {
        "hardLimit": 1024,
        "name": "nofile",
        "softLimit": 1024
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs"
    },
    "resourceRequirements": [
      {
        "type": "GPU",
        "value": "1"
      }
    ]
}
CONTAINER_PROPERTIES
}


resource "aws_batch_job_queue" "queue" {
  name     = var.name
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.compute.arn,
  ]
}
