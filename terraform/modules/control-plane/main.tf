resource "aws_kms_key" "eks_secrets" {
  description = "${var.env} EKS Secrets envelope encryption"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation = true

  tags = { Name = "${var.env}-eks-secrets-key"}
}

resource "aws_kms_alias" "eks_secrets" {
  name = "alias/${var.env}-eks-secrets"
  target_key_id = aws_kms_key.eks_secrets.id
}



resource "aws_cloudwatch_log_group" "eks_cluster" {
  name = "/aws/eks/${var.env}-cluster/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id = aws_kms_key.eks_secrets.id
  tags = { Name = "${var.env}-eks-cluster-logs" }
}



resource "aws_iam_role" "cluster" {
  name = "${var.env}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com"}
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "vpc_resource_controller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}



resource "aws_security_group" "cluster_endpoint_sg" {
  name = "${var.env}-cluster-endpoint-sg"
  vpc_id = var.vpc_id
  tags = { Name = "${var.env}-cluster-endpoint-sg"}
}

resource "aws_security_group_rule" "apiserver_from_operator" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = var.operator_cidrs
  security_group_id = aws_security_group.cluster_endpoint_sg.id
}

resource "aws_security_group_rule" "cluster_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster_endpoint_sg.id
}



resource "aws_eks_cluster" "cluster" {
  name     = "${var.env}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version = var.kubernetes_version

  vpc_config {
    subnet_ids = var.control_plane_subnet_ids
    security_group_ids = [aws_security_group.cluster_endpoint_sg.id]
    endpoint_private_access = true

    endpoint_public_access = var.enable_public_endpoint
    public_access_cidrs = var.enable_public_endpoint ? var.public_endpoint_cidrs : []
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit"
  ]

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.vpc_resource_controller
  ]

}



resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = { Name = "${var.env}-eks-oidc-provider" }
}

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
