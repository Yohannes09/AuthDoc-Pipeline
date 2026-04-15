output "vpc_id" { value = aws_vpc.vpc.id }

output "public_subnet_ids" {value = aws_subnet.public_subnet[*].id}
output "node_subnet_ids" { value = aws_subnet.node_subnet[*].id }
output "control_plane_subnet_ids" { value = aws_subnet.control_plane_subnet[*].id }
output "data_subnet_ids" { value = aws_subnet.data_subnet[*].id }