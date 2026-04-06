
output "kms_key_id" { value = aws_kms_key.kms_signing_key.id }
output "kms_key_arn"              { value = aws_kms_key.kms_signing_key.arn }

output "kms_sign_role_arn"        { value = aws_iam_role.kms_sign_role.arn }
output "kms_verify_role_arn"      { value = aws_iam_role.kms_verify_role.arn }

output "kms_sign_instance_profile" { value = aws_iam_instance_profile.kms_sign_profile.arn }
output "kms_verify_instance_profile" { value = aws_iam_instance_profile.kms_verify_profile}