//module: coleccion de recursos
module "vpc_back_1_us_east_2" {
  source          = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=efcac80"
  # solucionado CKV_TF_1
  # source  = "terraform-aws-modules/vpc/aws"
  # version = "6.3.0"
  //https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest

  name                 = "vpc_back_1_us_east_2"
  cidr                 = "10.1.0.0/16"
  //ditribuir subredes
  azs                  = data.aws_availability_zones.available_use2.names
  private_subnets      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets       = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
  //para acceder a los nodos de eks en las subredes privadas
  enable_nat_gateway   = true
  //una sola nat gateway
  single_nat_gateway   = true
  ////cambiar a api????
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "vpc_back_2_us_east_1" {
  source          = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=efcac80"
  # solucionado CKV_TF_1
  # source  = "terraform-aws-modules/vpc/aws"
  # version = "6.3.0"

  providers = {
    aws = aws.use1
  }

  name                 = "vpc_back_2_us_east_1"
  cidr                 = "10.2.0.0/16"
  //ditribuir subredes
  azs                  = data.aws_availability_zones.available_use1.names
  private_subnets      = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets       = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]

  enable_nat_gateway   = true

  single_nat_gateway   = true

  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name_2}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name_2}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name_2}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# Health checks
resource "aws_route53_health_check" "alb_us_east_1" {
  fqdn          = aws_lb.alb_us_east_1.dns_name
  port          = 443
  type          = "HTTPS"
  resource_path = "/health"
  failure_threshold = 3
  request_interval  = 30
  insufficient_data_health_status = "Unhealthy"
}

resource "aws_route53_health_check" "alb_us_east_2" {
  fqdn          = aws_lb.alb_us_east_2.dns_name
  port          = 443
  type          = "HTTPS"
  resource_path = "/health"
  failure_threshold = 3
  request_interval  = 30
  insufficient_data_health_status = "Unhealthy"
}

# Weighted records (round-robin 50/50). Note: name = "api" -> api.cineagile.com
resource "aws_route53_record" "api_us_east_1" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api"
  type    = "A"

  set_identifier = "us-east-1"
  weighted_routing_policy { weight = 50 }

  alias {
    name                   = aws_lb.alb_us_east_1.dns_name
    zone_id                = aws_lb.alb_us_east_1.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.alb_us_east_1.id
}

resource "aws_route53_record" "api_us_east_2" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api"
  type    = "A"

  set_identifier = "us-east-2"
  weighted_routing_policy { weight = 50 }

  alias {
    name                   = aws_lb.alb_us_east_2.dns_name
    zone_id                = aws_lb.alb_us_east_2.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.alb_us_east_2.id
}


resource "aws_lb" "alb_us_east_1" {
  provider           = aws.use1
  name               = "cineagile-alb-us-east-1"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_us_east_1.id]
  subnets            = module.vpc_back_2_us_east_1.public_subnets
}

resource "aws_lb" "alb_us_east_2" {
  provider           = aws
  name               = "cineagile-alb-us-east-2"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_us_east_2.id]
  subnets            = module.vpc_back_1_us_east_2.public_subnets
}

# --- Target Group para backend en us-east-1 ---
resource "aws_lb_target_group" "backend_us_east_1" {
  provider = aws.use1
  name     = "backend-tg-us-east-1"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = module.vpc_back_2_us_east_1.vpc_id 
  health_check {
    path                = "/health"
    protocol            = "HTTPS"
    matcher             = "200-299"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group" "backend_us_east_2" {
  name     = "backend-tg-us-east-2"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = module.vpc_back_1_us_east_2.vpc_id 
  health_check {
    path                = "/health"
    protocol            = "HTTPS"
    matcher             = "200-299"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

# --- Listener para ALB ---
resource "aws_lb_listener" "https_us_east_1" {
  provider = aws.use1
  load_balancer_arn = aws_lb.alb_us_east_1.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01" #checkov CKV_AWS_103 > Activar TLS
  certificate_arn   = aws_acm_certificate.cineagile_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_us_east_1.arn
  }
}

resource "aws_security_group" "alb_us_east_1" {
  provider    = aws.use1
  name        = "alb-sg-us-east-1"
  description = "Security group for ALB in us-east-1"
  vpc_id      = module.vpc_back_2_us_east_1.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg-us-east-1" }
}

resource "aws_security_group" "alb_us_east_2" {
  provider    = aws
  name        = "alb-sg-us-east-2"
  description = "Security group for ALB in us-east-2"
  vpc_id      = module.vpc_back_1_us_east_2.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg-us-east-2" }
}
