module "eks_us_east_2" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "21.3.1"

  name    = local.cluster_name
  kubernetes_version = "1.31"

  vpc_id   = module.vpc_back_1_us_east_2.vpc_id
  subnet_ids  = module.vpc_back_1_us_east_2.private_subnets


  # Para crear los ec2 node groups
  eks_managed_node_groups = {
    "ec2" = {
      instance_types                 = ["t3.small"]
      #additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      desired_size = 3
      min_size = 3
      max_size = 5
    }
  }
}

module "eks_us_east_1" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "21.3.1"

  name    = local.cluster_name_2
  kubernetes_version = "1.31"

  providers = {
    aws = aws.use1
  }

  vpc_id   = module.vpc_back_2_us_east_1.vpc_id
  subnet_ids  = module.vpc_back_2_us_east_1.private_subnets


  # Para crear los ec2 node groups
  eks_managed_node_groups = {
    "ec2" = {
      instance_types                 = ["t3.small"]
      #additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      desired_size = 3
      min_size = 3
      max_size = 5
    }
  }
}

/*
data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}*/



#https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/eks-managed-node-group/eks-al2023.tf
