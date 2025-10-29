/*
 ALB internet-facing
resource "aws_lb" "alb_east_1" {
  name               = "alb_east_1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_public_sg.id]
  subnets            = module.vpc_back_1_us_east_2.public_subnets
}

resource "aws_lb" "alb_east_2" {
  name     = "alb_east_2"
  internal = false
  load_balancer_type = "application"
  //security_groups    = [aws_security_group.alb_public_sg.id]
  subnets            = module.vpc_back_1_us_east_2.public_subnets
}


# Target group para API Gateway
resource "aws_lb_target_group" "alb_to_api_gateway" {
  name     = "alb-to-apigw"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc_back_1_us_east_2.name
}

# Listener HTTP


resource "aws_lb_listener" "public_alb_listener" {
  load_balancer_arn = alb_east_1.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_to_api_gateway.arn
  }
}
*/