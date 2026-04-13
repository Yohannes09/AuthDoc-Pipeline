# Internet
# → NLB (TCP passthrough, public subnet)
#   → Worker node IP : NodePort-A  (NGINX pod)
#     → NGINX terminates TLS, forwards plain HTTP
#       → Worker node IP : NodePort-B  (Kong pod)  ← internal, or ClusterIP
#         → Kong validates JWT, routes
#           → AuthMat / DocKeep pod

resource "aws_security_group" "worker_node_sg" {
  name = "${var.env}-worker-node-sg"
  vpc_id = var.vpc_id
  tags = { Name = "${var.env}-worker-node-sg" }
}

resource "aws_security_group_rule" "kubelet_from_control_plane" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  source_security_group_id = var.control_plane_sg_id
  security_group_id = aws_security_group.worker_node_sg.id
  description = "Kubelet API from control plane"
}

# NodePort range 30000 - 32767
# Needed for Kong ingress controller
resource "aws_security_group_rule" "nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks = [var.vpc_cidr]
  security_group_id = aws_security_group.worker_node_sg.id
  description = "NodePort range, VPC-local only"
}

# Pod-to-pod
resource "aws_security_group_rule" "pod_overlay" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.worker_node_sg.id
  security_group_id = aws_security_group.worker_node_sg.id
}

resource "aws_security_group_rule" "cilium_vxlan" {
  type = "ingress"
  from_port = 8472
  to_port = 8472
  protocol = "udp"
  source_security_group_id = aws_security_group.worker_node_sg.id
  security_group_id = aws_security_group.worker_node_sg.id
  description = "Cilium vxlan overlay between nodes"
}

resource "aws_security_group_rule" "cilium_health" {
  type              = "ingress"
  from_port         = 4240
  to_port           = 4240
  protocol          = "tcp"
  source_security_group_id = aws_security_group.worker_node_sg.id
  security_group_id = aws_security_group.worker_node_sg.id
  description = "Cilium node health check"
}

resource "aws_security_group_rule" "worker_node_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # Send traffic anywhere
  security_group_id = aws_security_group.worker_node_sg.id
  description = "Allow all egress via NAT"
}




resource "aws_iam_role" "worker_role" {
  name = "${var.env}-worker-role"

  assume_role_policy = jsonencode({
    Version : "2017-7-10"
    Statement: [{
      Effect : "Allow"
      Principal: { Service = "ec2.amazonaws.com" }
      Action: "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "worker_node_profile" {
  name = "${var.env}-worker-node-profile"
  role = aws_iam_role.worker_role.name
}





resource "aws_instance" "worker_node_ec2" {
  count = var.worker_node_count
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.worker_node_subnet_ids[count.index % length(var.worker_node_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.worker_node_sg.id]
  iam_instance_profile = aws_iam_instance_profile.worker_node_profile.name
  key_name = var.key_name

  root_block_device {
    volume_size = 5
    volume_type = ""
    encrypted = true
  }

  tags = { Name = "${var.env}-node-ec2" }
}