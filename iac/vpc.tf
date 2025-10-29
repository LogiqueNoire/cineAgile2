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