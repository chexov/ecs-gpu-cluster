
## Abstract

This modules and `examples/` folder shows how to quickly use AWS ECS as a managed solution to run your GPU enabled containers  

### Modules

`aws-batch-gpu/` -- creates AWS Batch Compute Environment with EC2 GPU Job Definition scaled to 0 instanecs


`ecs-sqs/` -- creates ECS cluster, SQS queue, AutoScaling Group and SpotFleet for processing tasks coming from SQS using worker passed into `var.ecr_image` 
