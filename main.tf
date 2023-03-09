terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.57.1"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}


data "aws_subnet_ids" "all" {
  vpc_id = "vpc-02f407155d8d26751"
}


#### SECURITY GROUP FOR APPLICATION LOAD BALANCER
resource "aws_security_group" "security-group-ot-2" {
  name        = "security_group_ot_2"
  description = "Allow outbound and inbound connection"
  vpc_id      = "vpc-02f407155d8d26751"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#### TARGET GROUP
resource "aws_alb_target_group" "target-group-ot" {
  name     = "target-group-ot"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-02f407155d8d26751"

  health_check {
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }


}


#### APPLICATION LOAD BALANCER
resource "aws_alb" "load-balancer-ot" {
  name            = "ot-alb"
  internal        = false
  security_groups = [aws_security_group.security-group-ot-2.id]
  subnets         = data.aws_subnet_ids.all.ids
}


#### LISTENER FOR APPLICATION LOAD BALANCER
resource "aws_alb_listener" "listener-ot" {
  load_balancer_arn = aws_alb.load-balancer-ot.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.target-group-ot.arn
  }
}

### AUTO SCALING GROUP
resource "aws_autoscaling_group" "auto-scaling-group-ot" {
  name                      = "auto_scaling_group_ot"
  max_size                  = 4
  min_size                  = 1
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300

  vpc_zone_identifier = data.aws_subnet_ids.all.ids
  target_group_arns   = [aws_alb_target_group.target-group-ot.arn]

  launch_template {
    id      = "lt-0896d535f9a9ac4f7"
    version = "$Latest"
  }

  metrics_granularity = "1Minute"

  lifecycle {
    create_before_destroy = true
  }


}

resource "aws_autoscaling_policy" "scale-up-ot" {
  autoscaling_group_name = aws_autoscaling_group.auto-scaling-group-ot.name
  name = "scale-up-policy-ot"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
       predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}

