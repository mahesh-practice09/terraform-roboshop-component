data "aws_ami" "devopsami" {
  most_recent = true
  owners      = ["973714476881"] # Canonical's AWS Account ID

  filter {
    name   = "name"
    values = ["Redhat-9-DevOps-Practice"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.Project}/${var.environment}/vpc"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name  = "/${var.Project}/${var.environment}/private_subnet_ids"
}

data "aws_ssm_parameter" "sg_id" {
  name = "/${var.Project}/${var.environment}/${var.component}_sg_id"
}

data "aws_ssm_parameter" "backendalb_listener" {
  name  = "/${var.Project}/${var.environment}/backendalb_listener_arn"
}

data "aws_ssm_parameter" "frontendalb_listener" {
  name  = "/${var.Project}/${var.environment}/frontendalb_listener_arn"
}