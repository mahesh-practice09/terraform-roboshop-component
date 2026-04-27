locals {
    private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
    instance_type = var.instance_type
    sg_id = data.aws_ssm_parameter.sg_id.value
    health_check_path = var.component == "frontend" ?  "/" : "/health"
    frontend_listener = data.aws_ssm_parameter.frontendalb_listener.value
    backend_listener = data.aws_ssm_parameter.backendalb_listener.value
    listener_arn = var.component == "frontend" ? local.frontend_listener : local.backend_listener
    port_number =  var.component == "frontend" ?  "80": "8080"
    frontend_header = "${var.component}-${var.environment}.${var.domain_name}"
    backend_header = "${var.component}.backend-alb-${var.environment}.${var.domain_name}"
    host_header = var.component == "frontend" ? local.frontend_header :  local.backend_header
    environment = "sbx"
    common_tags = {
        Project = var.Project
        Terraform = true
        Env = var.environment
      }
  
}     