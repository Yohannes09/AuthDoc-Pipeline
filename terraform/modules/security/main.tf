resource "aws_security_group" "app" {
  name        = "${var.name}-sg"
  description = "Allow selected incoming traffic."
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
    description = "SSH from trusted CIDRs"
  }
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "App port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}


resource "aws_iam_role" "ec2_s3_access_role" {
  name = "${var.name}-ec2-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = var.tags
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ec2_s3_access_role.name
}



resource "aws_iam_policy" "ec2_s3_policy" {
  name   = "${var.name}-ec2-s3-policy"
  policy = data.aws_iam_policy_document.ec2_s3_policy.json
}

data "aws_iam_policy_document" "ec2_s3_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      var.dockeep_bucket_arn,
      "${var.dockeep_bucket_arn}/*"
    ]
    effect = "Allow"
  }
}