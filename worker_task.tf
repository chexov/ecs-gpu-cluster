resource "aws_ecs_service" "worker" {
  depends_on = [
  aws_iam_role_policy.ecr_access]

  name                = local.service_name
  cluster             = aws_ecs_cluster.cluster.id
  scheduling_strategy = "DAEMON"
  task_definition     = aws_ecs_task_definition.worker_task_definition.arn
}

resource "aws_ssm_parameter" "ecs-cwagent-sidecar-ec2" {
  name  = "${var.cluster_name}-ecs-cwagent-sidecar-ec2"
  type  = "String"
  value = <<EOF
{
  "metrics": {
    "namespace": "ecs/${local.service_name}",
    "metrics_collected": {
      "statsd": {
        "service_address": ":8125"
      }
    }
  }
}

EOF
}

resource "aws_ecs_task_definition" "worker_task_definition" {
  execution_role_arn = aws_iam_role.ecs-instance.arn
  family             = local.service_name
  network_mode       = "bridge"
  //  count = 1
  requires_compatibilities = [
  "EC2"]
  tags = {
    Name      = "Worker Task Def"
    Terraform = true
  }
  container_definitions = <<EOF
[
  {
    "name": "${local.service_name}",
    "image": "${var.ecr_image}",
    "essential": true,
    "mountPoints": [],
    "volumesFrom": [],
    "memoryReservation": 8000,
    "links": [
      "cloudwatch-agent"
    ],
    "environment": [
      {
        "name": "DEBUG",
        "value": "False"
      },
      {
        "name": "AWS_SQS_QUEUE",
        "value": "${data.aws_arn.sqs_arn.resource}"
      },
      {
        "name": "STATSD_HOST",
        "value": "cloudwatch-agent"
      },
      {
        "name": "STATSD_PORT",
        "value": "8125"
      },
      {
        "name": "STATSD_SAMPLE_RATE",
        "value": "1"
      },
      {
        "name": "STATSD_DISABLED",
        "value": "False"
      }
    ],
    "portMappings": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group": "True",
        "awslogs-group": "${var.awslogs_group_detectron}",
        "awslogs-region": "${var.awslogs_region}",
        "awslogs-stream-prefix": "${local.service_name}"
      }
    },
    "resourceRequirements": [
      {
        "type": "GPU",
        "value": "1"
      }
    ]
  },
  {
    "name": "cloudwatch-agent",
    "image": "amazon/cloudwatch-agent:latest",
    "essential": true,
    "mountPoints": [],
    "portMappings": [],
    "volumesFrom": [],
    "cpu": 0,
    "memoryReservation": 256,
     "environment": [
          {
            "name": "FORCE_REDEPLOY_INC",
            "value": "2"
          }],
    "secrets": [
      {
        "name": "CW_CONFIG_CONTENT",
        "valueFrom": "${aws_ssm_parameter.ecs-cwagent-sidecar-ec2.name}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group": "True",
        "awslogs-group": "${var.awslogs_group_cwagent}",
        "awslogs-region": "${var.awslogs_region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]

EOF

}

