data "aws_availability_zones" "available" {}

locals {
  cluster_name = "cineagile-eks-942"
  cluster_name_2 = "cineagile-eks-111"
}