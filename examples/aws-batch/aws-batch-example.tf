provider "aws" {
  profile = "dev"
  region  = "us-east-1"
}


locals {
  name   = "timecode-gpu"
  vpc_id = "vpc-fa7fb49e"
  vpc_subnets = [
    "subnet-e4ed8681",
    "subnet-b17167c6",
    "subnet-6d11d250",
    "subnet-350b9c39",
    "subnet-a87c54f1",
    "subnet-335f0118"
  ]
}

resource "aws_security_group" "sg" {
  name   = "${local.name}-sg"
  vpc_id = local.vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

module "batch" {
  source = "../../aws-batch-gpu"

  name   = local.name
  vpc_id = local.vpc_id
  security_group_ids = [
    aws_security_group.sg.id
  ]
  subnets = local.vpc_subnets

  instance_type = "g4dn.xlarge"
  ecr_image     = "355688248694.dkr.ecr.us-east-1.amazonaws.com/timecodes-gpu:worker-0.0.5"
  worker_command = [
    "--jsonpath",
    "https://timecodes-test.s3.us-west-1.amazonaws.com/sdi_request_aws_test.json"
  ]
  worker_env = [
    {
      name : "APIKEY",
      value : "sha256sha256"
    }
  ]
  worker_memory_mb = "2048"
}