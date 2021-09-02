output "spot_fleet_id" {
  value = aws_spot_fleet_request.ecs_spot_nodes.id
}

output "autoscalinggroup_name" {
  value = aws_autoscaling_group.worker-autoscale.name
}
