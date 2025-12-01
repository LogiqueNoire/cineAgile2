data "aws_availability_zones" "available_use2" {}

data "aws_availability_zones" "available_use1" {
  provider = aws.use1
}

locals {
  cluster_name   = "cineagile-eks-942"
  cluster_name_2 = "cineagile-eks-111"
}