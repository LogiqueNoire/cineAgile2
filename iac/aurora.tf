# ==================================================
# Aurora DSQL Cluster - Región Principal (us-east-2)
# ==================================================
resource "aws_dsql_cluster" "dsql_east2" {
  provider = aws
  region   = "us-east-2"

  deletion_protection_enabled = false

  multi_region_properties {
    witness_region = "us-east-1"
  }

  tags = {
    Name = "dsql-east2"
  }
}

# ==================================================
# Aurora DSQL Cluster - Región Secundaria (us-east-1)
# ==================================================
resource "aws_dsql_cluster" "dsql_east1" {
  provider = aws.use1
  region   = "us-east-1"

  deletion_protection_enabled = false

  multi_region_properties {
    witness_region = "us-east-2"
  }

  tags = {
    Name = "dsql-east1"
  }
}

# ==================================================
# Peering bidireccional entre los clusters
# ==================================================
resource "aws_dsql_cluster_peering" "east2_to_east1" {
  provider       = aws.use1
  identifier     = aws_dsql_cluster.dsql_east2.identifier
  clusters       = [aws_dsql_cluster.dsql_east1.arn]
  witness_region = "us-east-1"

  timeouts {
    create = "30m"
  }
}

resource "aws_dsql_cluster_peering" "east1_to_east2" {
  provider       = aws
  identifier     = aws_dsql_cluster.dsql_east1.identifier
  clusters       = [aws_dsql_cluster.dsql_east2.arn]
  witness_region = "us-east-1"

  timeouts {
    create = "30m"
  }
}

//https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest