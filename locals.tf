locals {
  service_name = "${var.cluster_name}-detectron"
  queue_name   = data.aws_arn.sqs_arn.resource

  root_size_gb = 42

  users = [
    {
      name     = "anton"
      fullname = "Anton"
      ssh_authorized_keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCXQGTVdKlpONeVF+eVGTPbpPDAeHrqqzYojevnrH0YXt70puhlWpAbYn+J+7TLuFmvPCfXRihtyVbmHcAe7XJEgch0WdQwH8NGjaDJ0OvIQhSzlbR4yIulQsHJDNYUmlyowM8MKh6OBEXDTyNKG3EQaSGElcd76trQL857UR7tICraCmHP114loNV34oyxAzAobnjgN0NfEoWqAijp9bBukEhFr9vlJkVYY5B9gazHHcUlDTPW60OyqcXZ38d95+0zgEM0TbTu19gsgX2AV0GmnXxmO5r3DCrkZ5PoXu1796AaxmFC0Nkd8Yk0ATq6zJkJBW4xXFs2Dww/tQYf8VQr chexov@anton.local",
      ]
    },
  ]


  userdata = templatefile("${path.module}/templates/userdata.tmpl",
    {
      users        = local.users,
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
