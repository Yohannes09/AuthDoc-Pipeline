resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.env}-node-group"
  node_role_arn   = aws_iam_role.worker_role.arn
  subnet_ids      = var.worker_subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  depends_on = [
    aws_iam_role_policy_attachment.ec2_container_registry,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]

}



resource "aws_iam_role" "worker_role" {
  name = "${var.env}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_role.name
}



resource "aws_security_group" "worker_sg" {
  name = "${var.env}-sg"
  vpc_id = var.vpc_id
  tags = {}
}

resource "aws_security_group_rule" "worker_internal_ingress" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  source_security_group_id = aws_security_group.worker_sg.id
  security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "control_plane_kubelet_ingress" {
  type = "ingress"
  from_port = 10250
  to_port = 10250
  protocol = "tcp"
  source_security_group_id = var.cluster_sg_id
  security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "control_plane_webhook_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = var.cluster_sg_id
  security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker_sg.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "worker_to_apiserver" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = var.cluster_sg_id
  source_security_group_id = aws_security_group.worker_sg.id
}



data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ebs_kms_policies" {
  statement {
    sid = "Admin"
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
      type = "AWS"
    }
    actions = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid = "AllowEC2EBS"
    effect = "Allow"

    principals {
      type = "Service"
      Identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
    ]

    resources = ["*"]
  }

  # `CreateGrant` allows ASG to launch encrypted volumes
  statement {
    sid = "AllowASGServiceRole"
    effect = "Allow"

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
      type = "AWS"
    }

    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]

    resources = ["*"]
  }

}

resource "aws_kms_key" "ebs_key" {
  description = "${var.env} EKS worker EBS encryption key"
  deletion_window_in_days = var.ebs_key_deletion_window_days
  enable_key_rotation = var.ebs_key_enable_key_rotation
  policy = data.aws_iam_policy_document.ebs_kms_policies.json
}

resource "aws_kms_alias" "ebs_key_alias" {
  name = "alias/${var.env}-eks-ebs"
  target_key_id = aws_kms_key.ebs_key.id
}



resource "aws_launch_template"  "worker" {
  name_prefix = "${var.env}-eks-worker-"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type = "gp3"
      volume_size = var.worker_volume_size_gb
      encrypted = true
      kms_key_id = aws_kms_key.ebs_key.id
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags = "enabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.env}-eks-worker"}
  }

  lifecycle {
    create_before_destroy = true
  }
}