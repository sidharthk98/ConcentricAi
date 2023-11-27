
# --------------------------------------------------------------------------------
# EKS-Cluster

resource "aws_security_group" "allow_bastion" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.public_cidr]
  }

  tags = {
    Name = "allow_tls"
  }
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv6   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  # version = "19.15.3"

  cluster_name    = "private-eks"
  cluster_version = "1.27"

  vpc_id                         = var.vpc.id
  subnet_ids                     = [var.subnet-1.id, var.subnet-2.id]
  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }
  cluster_addons = {
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }
  cluster_additional_security_group_ids = [aws_security_group.allow_bastion.id]
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    for role in var.aws_auth_roles : {
      rolearn  = role.arn
      username = "system-node:{{SessionName}}"
      groups   = ["system:masters"]
    }
  ]
  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

# --------------------------------------------------------------
#Kubernetes provider

data "aws_eks_cluster" "default" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}


