// Trust policy for both execution + task roles (same principal).
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

// ECS task execution role: pulls images, writes logs. AWS-managed policy is the canonical fit.
resource "aws_iam_role" "execution" {
  name               = "ecs-execution-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

// AWS-managed execution policy - exactly the perms ECS agent needs.
resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// Task role - separate identity for the workload itself, scoped to logs only.
resource "aws_iam_role" "task" {
  name               = "ecs-task-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

// Least-priv inline policy: only the log groups owned by this stack.
data "aws_iam_policy_document" "task_inline" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${local.account_id}:log-group:/ecs/${var.env}/*:*",
    ]
  }
}

// Inline task policy attachment.
resource "aws_iam_role_policy" "task_inline" {
  name   = "task-inline-${var.env}"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_inline.json
}

// EC2 instance role - required so the ECS agent on the host can register/heartbeat.
resource "aws_iam_role" "ec2" {
  name = "ecs-instance-${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

// Managed policy for ECS-on-EC2 hosts.
resource "aws_iam_role_policy_attachment" "ec2_ecs" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

// SSM Session Manager - replaces SSH; uses the SSM endpoints from 10-network.
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// Instance profile binds the role to EC2 instances.
resource "aws_iam_instance_profile" "ec2" {
  name = "ecs-instance-${var.env}"
  role = aws_iam_role.ec2.name
}
