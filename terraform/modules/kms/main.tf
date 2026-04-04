
data "aws_caller_identity" "current_caller" {}

data "aws_region" "current_region" {}

resource "aws_kms_key" "kms_signing_key" {
  description              = "Asymmetric KMS key for signing and verification"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  enable_key_rotation      = false

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "",
    "Statement" : [{
      "Sid" : "AllowRootAccountEmergencyAccess",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.current_caller.account_id}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
    },
    {
      "Sid" : "AllowAuthServiceSigning",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.current_caller.account_id}:role/${aws_iam_role.kms_sign_role.name}"
      },
      "Action" : [
        "kms:Sign",
        "kms:GetPublicKey",
        "kms:DescribeKey"
      ],
      "Resource" : "*"
    },
    {
        "Sid" : "AllowVerifyingServices",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current_caller.account_id}:role/${aws_iam_role.kms_verify_role.name}"
        },
        "Action" : "kms:GetPublicKey",
        "Resource" : "*"
    }]
  })
}


# ********************* SIGN *******************

resource "aws_iam_policy" "kms_sign_policy" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
        "Sid" : "",
        "Effect" : "Allow",
        "Action" : [
          "kms:Sign",
          "kms:GetPublicKey",
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:kms:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:key/${aws_kms_key.kms_signing_key.id}"
    }]
  })
}

resource "aws_iam_role" "kms_sign_role" {
  name = "${var.env}-kms-sign-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "kms_sign_attach" {
  policy_arn = aws_iam_policy.kms_sign_policy.arn
  role       = aws_iam_role.kms_sign_role.name
}

resource "aws_iam_instance_profile" "kms_sign_profile" {
  name = "${var.env}-kms-sign-profile"
  role = aws_iam_role.kms_sign_role.name
}


# ********************* VERIFY *******************

resource "aws_iam_policy" "kms_verify" {
  policy = jsonencode({
    "version" : "2012-10-17",
    "statement" : [{
      "Sid" : "",
      "Effect" : "Allow",
      "Action" : [
        "kms:GetPublicKey"
      ],
      "Resource" : "arn:aws:kms:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:key/${aws_kms_key.kms_signing_key.id}"
    }]
  })
}

resource "aws_iam_role" "kms_verify_role" {
  name = "${var.env}-kms-verify-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "kms_verify_attach" {
  policy_arn = aws_iam_policy.kms_verify.arn
  role       = aws_iam_role.kms_verify_role.name
}

resource "aws_iam_instance_profile" "kms_verify_profile" {
  name = "${var.env}-kms-verfiy-profile"
  role = aws_iam_role.kms_verify_role.name
}