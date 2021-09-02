data "aws_arn" "sqs_arn" {
  arn = var.sqs_in_arn
}

data "aws_iam_policy_document" "ecrpolicy" {
  statement {
    sid    = "ecr"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage"
    ]
    resources = [
    "*"]
  }

  statement {
    sid    = "AllSQS"
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:ListQueues"
    ]
    resources = [
      var.sqs_in_arn
    ]
  }

  statement {
    sid    = "Metrics"
    effect = "Allow"
    actions = [
    "cloudwatch:PutMetricData"]
    resources = [
    "*"]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
    "arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = aws_iam_role.ecs-instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy" "ecr_access" {
  name   = "${var.cluster_name}-woeker-role"
  role   = aws_iam_role.ecs-instance.id
  policy = data.aws_iam_policy_document.ecrpolicy.json
}

data "aws_iam_policy_document" "ssm" {
  statement {
    sid    = "SSMget"
    effect = "Allow"
    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
    "ssm:GetParameter"]
    resources = [
    aws_ssm_parameter.ecs-cwagent-sidecar-ec2.arn]
  }
}

resource "aws_iam_role_policy" "ssm_access" {
  name   = "${var.cluster_name}-ssm_access_role"
  role   = aws_iam_role.ecs-instance.id
  policy = data.aws_iam_policy_document.ssm.json
}
