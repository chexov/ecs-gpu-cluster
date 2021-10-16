variable "ecr_image" {
  description = "ECR image full URL which will be deployed as a Daemon task"
  type        = string
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group ID for EC2 nodes"
}

variable "worker_env" {
  type = list(object({
    name : string,
    value : string
  }))

  default = []
}

variable "worker_command" {
  type = list(string)
}

variable "worker_memory_mb" {
  type = string
}

variable "instance_type" {
  description = "EC2 node instance type"
  type        = string
}

variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}
