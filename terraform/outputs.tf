output "ec2_ip" {
  value = aws_instance.authdoc_app.public_ip
}