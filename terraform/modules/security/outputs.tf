output "sg_id" {
  value = aws_security_group.app.id
}
output "instance_profile_arn" {
  value = aws_iam_instance_profile.ec2_profile.arn
}
output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}