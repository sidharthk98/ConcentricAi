terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6.2"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"
}



# ----------------------------------------------------------
# EKS IAM Role

data "aws_iam_policy_document" "eks-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster-role" {
  name               = "eks-private-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks-assume_role.json
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster-role.name
}



module "vpc" {
  source = "./modules/vpc"
}

module "ec2" {
  source = "./modules/ec2"
  subnet = module.vpc.default-public.id
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "workload-artifacts-cai"
}

module "eks" {
  source = "./modules/eks"
  vpc = module.vpc.vpc
  subnet-1 = module.vpc.default-private-1
  subnet-2 = module.vpc.default-private-2
  public_cidr = module.vpc.default-public.cidr_block
  aws_auth_roles = [module.ec2.bastion_role]
  # depends_on = [ module.ec2 ]
}
# ------------------------------------------------------------
# Node group role

data "aws_iam_policy_document" "node-group-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node-group-role" {
  name               = "cluster-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.node-group-assume_role.json
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-group-role.name
}
# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-group-role.name
}

# -------------------------------------------------------------------------------
# EC2 Instance

