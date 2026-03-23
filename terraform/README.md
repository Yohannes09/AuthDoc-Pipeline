# Terraform for AuthDoc (AuthMat + DocKeep)

Structure:
- modules/: reusable modules (network, security, ec2, s3, monitoring)
- environments/: per-environment wiring and backend config (dev, prod)

Quickstart (dev):
1. cd environments/dev
2. terraform init
3. terraform apply -var="ami=ami-..." -auto-approve