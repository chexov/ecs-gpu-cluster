locals {
  service_name = "${var.cluster_name}-worker"
  queue_name   = data.aws_arn.sqs_arn.resource

  root_size_gb = 42

  userdata = templatefile("${path.module}/templates/userdata.tmpl",
    {
      users        = var.ec2_instance_users,
      groups       = "admin,docker",
      shell        = "/bin/bash",
      sudo         = "ALL=(ALL) NOPASSWD:ALL"
      cluster_name = aws_ecs_cluster.cluster.name
    }
  )

  tags = {
    Cluster   = var.cluster_name,
    Terraform = true,
  }
}
