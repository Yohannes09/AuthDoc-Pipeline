
// TODO:
data "aws_caller_identity" "current" {

}

resource "aws_kms_key" "kms_signing_key" {
  description              = "Asymmetric KMS key for signing and verification"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  enable_key_rotation      = false

  policy = jsonencode({

  })
}

resource "aws_iam_policy" "kms_sign" {
  policy = jsondecode({
    "version" : "2012-10-17",
    "statement" : [{
        "Sid" : "",
        "Effect" : "Allow",
        "Action" : [
          "kms:Sign",
          "kms:GetPublicKey",
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:kms:<Region>:<Account>:key/${aws_kms_key.kms_signing_key.id}"
    }]
  })
}

resource "aws_iam_policy" "kms_verify" {
  policy = jsondecode({
    "version" : "2012-10-17",
    "statement" : [{
      "Sid" : "",
      "Effect" : "Allow",
      "Action" : [
        "kms:GetPublicKey"
      ],
      "Resource" : "arn:aws:kms:<Region>:<Account>:key/${aws_kms_key.kms_signing_key.id}"
    }]
  })
}

resource "aws_iam_role" "kms_sign_role" {
  assume_role_policy = aws_iam_policy.kms_sign.policy
}


resource "aws_iam_role" "kms_sign_role" {
  assume_role_policy = ""
}