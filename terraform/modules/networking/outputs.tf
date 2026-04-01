output "vpc_id" {
  value = aws_vpc.authmat_dockeep_vpc.id
}

output "authmat_subnet_id" {
  value = aws_subnet.authmat_subnet.id
}

output "dockeep_subnet_id" {
  value = aws_subnet.dockeep_subnet.id
}

output "sg_id" {
  value = aws_security_group.authmat-dockeep-sg.id
}