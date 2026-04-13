resource "aws_security_group" "control_plane_sg" {
  name = "${var.env}-control-plane-sg"
  vpc_id = var.vpc_id
  tags = { Name = "${var.env}-control-plane-sg" }
}

# apiserver typically listens on port 6443
resource "aws_security_group_rule" "apiserver_from_nodes" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  source_security_group_id = var.worker_node_sg_id
  security_group_id = aws_security_group.control_plane_sg.id
  description = "kube-apiserver from worker nodes"
}

// E.g., K8s -> apiserver
resource "aws_security_group_rule" "apiserver_from_operator" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane_sg.id
  cidr_blocks = [var.operator_cidr]
  description = "kube-apiserver from operator/CI"
}

resource "aws_security_group_rule" "etcd_internal" {
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  security_group_id = aws_security_group.control_plane_sg.id
  description = ""
}

# apiserver -> local control plane kubelet, and other control plane's kubelet
# Port 10250: Permits communication from the apiserver to the kubelet running the control plane, and serves the node health API
# This sg rule permits control planes on different nodes to communicate
resource "aws_security_group_rule" "kubelet_from_apiserver" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  source_security_group_id = aws_security_group.control_plane_sg.id
  security_group_id = aws_security_group.control_plane_sg.id
}

resource "aws_security_group_rule" "control_plane_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.control_plane_sg.id
  description = "Allow all egress"
}




resource "aws_iam_role" "control_plane_role" {
  name = "${var.env}-control-plane-role"
  assume_role_policy = jsonencode({
    Versions = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com"}
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "control_plane_rta" {
  role       = aws_iam_role.control_plane_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "control_plane_profile" {
  name = "${var.env}-control-plane-profile"
  role = aws_iam_role.control_plane_role.name
}




# If 3 EC2 instances are created but have only 2 subnets defined
# Instance 0: 0 % 2 = 0 (uses first subnet)
# Instance 1: 1 % 2 = 1 (uses second subnet)
# Instance 2: 2 % 2 = 0 (use first subnet again)
resource "aws_instance" "control_plane_ec2" {
  count = var.control_plane_node_count
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.control_plane_subnet_ids[count.index % length(var.control_plane_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.control_plane_sg.id]
  iam_instance_profile = aws_iam_instance_profile.control_plane_profile.name
  key_name = var.key_name
  root_block_device {
    volume_size = 5 # 5GB
    volume_type = "" # E.g., "gp3"
    encrypted = true
  }
  tags = { Name = "${var.env}-control-plane-ec2" }
}