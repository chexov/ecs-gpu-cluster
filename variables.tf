variable "cluster_name" {
  default = "ecs-gpu-cluster"
  type    = string
}

variable "ecr_image" {
  description = "ECR image full URL which will be deployed as a Daemon task"
  type        = string
}

variable "subnet_id" {
  description = "subnet in which ec2 instance will be running"
  type        = string
}

variable "vpc_id" {
  description = "VPC id in which ec2 ECS node will be running"
  type        = string
}

variable "sqs_in_arn" {
  description = "ARN for input SQS queue for gpu worker"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for spot fleet and ec2 instances"
  type        = string
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for EC2 nodes"
}

variable "awslogs_group_detectron" {
  type = string
}
variable "awslogs_region" {
  type = string
}
variable "awslogs_group_cwagent" {
  type = string
}
