resource "aws_instance" "main" {
   ami = data.aws_ami.devopsami.image_id
   instance_type = local.instance_type
   subnet_id = local.private_subnet_ids[0]
   vpc_security_group_ids = [ local.sg_id ]
   tags = merge(local.common_tags, 
    { Name = "${var.Project}-${var.environment}-${var.component}"})      #    Roboshop-sbx-catalogue
}

resource "terraform_data" "main" {
    triggers_replace = [aws_instance.main.id]
  

     provisioner "file" {
        source = "bootstrap.sh"
        destination = "/tmp/bootstrap.sh"
     }

     provisioner "remote-exec" {
      inline = [ "chmod +x /tmp/bootstrap.sh" ,
                 "sudo sh /tmp/bootstrap.sh ${var.component} ${var.environment} ${var.app_version}" ]
    }

    connection {
         type = "ssh"
         user = "ec2-user"
         password = "DevOps321"
         host = aws_instance.main.private_ip
    }
   
}

resource "aws_ec2_instance_state" "main" {
  instance_id = aws_instance.main.id
  state       = "stopped"
  depends_on = [ terraform_data.main ]
}

resource "aws_ami_from_instance" "main" {
  name               = "${var.Project}-${var.environment}-${var.component}"
  source_instance_id = aws_ec2_instance_state.main.id

  depends_on = [ aws_ec2_instance_state.main ]
}


resource "aws_lb_target_group" "main" {
   name =  "${var.Project}-${var.environment}-${var.component}-tg"
   port = local.port_number
   protocol = "HTTP"
   vpc_id = data.aws_ssm_parameter.vpc_id.value
   deregistration_delay = 60

   health_check {
      protocol = "HTTP"
      path = local.health_check_path
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 5
      interval = 10
      matcher = "200-299"
      port = local.port_number
   } 
}



resource "aws_launch_template" "main" {
  name =  "${var.Project}-${var.environment}-${var.component}"
  vpc_security_group_ids = [ local.sg_id ]
  instance_initiated_shutdown_behavior = "terminate"
  update_default_version = true
  image_id = aws_ami_from_instance.main.id
  instance_type = local.instance_type
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }

  tag_specifications {
    resource_type = "instance"

     tags = merge(local.common_tags, 
    { Name = "${var.Project}-${var.environment}-${var.component}"})   
  
  }
  tag_specifications {
    resource_type = "volume"

     tags = merge(local.common_tags, 
    { Name = "${var.Project}-${var.environment}-${var.component}"})   
  
  }
  }

  resource "aws_autoscaling_group" "main" {
  name =  "${var.Project}-${var.environment}-${var.component}"
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 120
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = false
  launch_template {
    id = aws_launch_template.main.id
    version = "$Latest"
  }
  vpc_zone_identifier       = [local.private_subnet_ids[0]]
  target_group_arns = [ aws_lb_target_group.main.arn ]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = [ "launch_template" ]
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, 
    { Name = "${var.Project}-${var.environment}-${var.component}"})   
    content {
    key                 = tag.key
    value               = tag.value
    propagate_at_launch = true
    }
  }

  timeouts {
    delete = "15m"
  }

  }


resource "aws_autoscaling_policy" "main" {
  name =  "${var.Project}-${var.environment}-${var.component}"
  autoscaling_group_name = aws_autoscaling_group.main.name
  estimated_instance_warmup = 120
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
  
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = local.listener_arn
  priority     = var.rule_priority
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  condition {
     host_header {
        values = [ local.host_header ]
        # catalogue.backend-sbx-alb.daws88s.shop
        # frontend-sbx-alb.daws88s.shop
    }
     }
  }


resource "terraform_data" "main_delete" {
   depends_on = [ aws_autoscaling_policy.main ]
   triggers_replace = [ aws_instance.main.id ]
   provisioner "local-exec" {
      command = " aws ec2 terminate-instances --instance-ids ${aws_instance.main.id}"
   }
}