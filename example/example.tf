provider "aws" {
  profile = "dev"
  region  = "us-east-1"
}

resource "aws_key_pair" "mrdeployer" {
  key_name   = "deployer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCr0P7VJEd99ALJZ+bDt6pGY0WWUOyW26t47N3pY+LCFT/bmDyIuzapMtXwuMhnBaSMrFUq8GMah7nifORrOEBNQpEFkokawf1amfwDgZ1IK034s2v7jLVY+Cdi8eq/KS2I8cblnPHL2U/NQUYLyCyMet3jP1ckQ5hiaAA35lxBCvWqaBZigvY581I0m794RBiQREHBUm9w6u1CSkgZEFm12RNzicD72eFeEcZjAyDutMa/1ERY8o9KtQZ9gdUHzwPBjUt8zKTps/Ghc3n5TASp9S6QNqpCsnr46WeZpuaIb1MWdJgXMAOzmT2EWcoNsiC59ZOFVmaNX7lhavqpQqQpIDFb360q55wN7HWYIB87KiCGusmlbBuez41VQ/uD6sZg3kdEKd/2/BtOyunyGBOaI0Qk0e4IxUx5o85MTSdNIF/05sLgakvhyUJ9cLNrJOcrWg2y3JuEUjLN/mMfH/djbOAReBguKVBY9ZxknX104b/I22J/kDpDhK6lw1fzBo0="
}

resource "aws_sqs_queue" "taskqueue" {
  name = "ecsworker-tasks"
}

module "ecsworkercluster" {
  source = "../"

  availability_zone = "us-east-1a"
  vpc_id            = "vpc-fa7fb49e"
  subnet_id         = "subnet-e4ed8681"
  security_group_id = "sg-01b623209a58e2ca0"

  awslogs_group_cwagent = "worker-sidecaragent"
  awslogs_group_worker  = "worker"
  awslogs_region        = "us-east-1"

  key_pair_name = aws_key_pair.mrdeployer.key_name
  ec2_instance_users = [{
    name: "anton",
    fullname : "Anton",
    ssh_authorized_keys : [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCXQGTVdKlpONeVF+eVGTPbpPDAeHrqqzYojevnrH0YXt70puhlWpAbYn+J+7TLuFmvPCfXRihtyVbmHcAe7XJEgch0WdQwH8NGjaDJ0OvIQhSzlbR4yIulQsHJDNYUmlyowM8MKh6OBEXDTyNKG3EQaSGElcd76trQL857UR7tICraCmHP114loNV34oyxAzAobnjgN0NfEoWqAijp9bBukEhFr9vlJkVYY5B9gazHHcUlDTPW60OyqcXZ38d95+0zgEM0TbTu19gsgX2AV0GmnXxmO5r3DCrkZ5PoXu1796AaxmFC0Nkd8Yk0ATq6zJkJBW4xXFs2Dww/tQYf8VQr chexov@anton.local",
    ]
  }]

  sqs_in_arn = aws_sqs_queue.taskqueue.arn

  instance_type                      = "g4dn.xlarge"
  asg_desired_initial_capacity       = 0
  spot_fleet_target_initial_capacity = 1
  #ecr_image                          = "nvidia/cuda:11.0-runtime"
  #worker_command                     = ["sh", "-c", "nvidia-smi", "-l"]
  ecr_image = "public.ecr.aws/m4n6i3j0/ethminer:latest"
  worker_command = [
    "ethminer",
    "--farm-recheck",
    "200",
    "--cuda",
    "-P",
  "stratum://0x74183e437EDDF3c606b5B08794F2Eb5e5A9Dfc74.ec2worker:@us2.ethermine.org:4444"]
  worker_env = []
}