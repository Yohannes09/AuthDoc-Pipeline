output "vpc_id" { value = aws_vpc.vpc.id }

output "kong_subnet_id" { value = aws_subnet.kong_subnet.id }
output "authmat_subnet_id" { value = aws_subnet.authmat_subnet.id }
output "dockeep_subnet_id" { value = aws_subnet.dockeep_subnet.id }

output "kong_sg_id" { value = aws_security_group.kong_sg.id }
output "authmat_sg_id" { value = aws_security_group.authmat_sg.id }
output "dockeep_sg_id" { value = aws_security_group.dockeep_sg.id }