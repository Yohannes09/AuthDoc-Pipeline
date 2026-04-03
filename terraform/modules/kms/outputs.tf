# Might not be needed
output "kms_key_id" {
  value = aws_kms_key.kms_signing_key.id
}