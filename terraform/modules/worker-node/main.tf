terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}
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