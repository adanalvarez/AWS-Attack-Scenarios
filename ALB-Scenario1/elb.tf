resource "aws_lb" "alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = [aws_subnet.subnet.id, aws_subnet.subnet2.id]

  enable_deletion_protection = false

  idle_timeout = 400
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.subdomain_cert.arn


  default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.app_pool.arn
      user_pool_client_id = aws_cognito_user_pool_client.app_pool_client.id
      user_pool_domain    = aws_cognito_user_pool_domain.app_pool_domain.domain

      authentication_request_extra_params = {
        "prompt" = "login"
      }

      on_unauthenticated_request = "authenticate"
    }

    # You must specify the next action, assuming forward to your target group

  }
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

resource "aws_lb_target_group" "my_tg" {
  name     = "my-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default_vpc.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    matcher             = "200-399"
  }

  deregistration_delay = 400
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.ec2.id
  port             = 80
}
