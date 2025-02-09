provider "aws" {
  region = "ap-northeast-2"
}

# VPC 생성
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

# 서브넷 생성
resource "aws_subnet" "eks_subnet" {
  count             = 2
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

# Pod 전용 서브넷
resource "aws_subnet" "pod_subnet" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "pod-subnet"
  }
}

# EKS 클러스터 생성
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.6.0" # 사용 가능한 최신 안정화 버전 확인 필요
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.30"

  vpc_id     = aws_vpc.eks_vpc.id
  subnet_ids = concat(aws_subnet.eks_subnet[*].id, aws_subnet.pod_subnet[*].id)

  eks_managed_node_groups = {
    eks_nodes = {
      desired_size    = 2
      max_size        = 3
      min_size        = 1
      instance_types  = ["t3.medium"]
    }
  }

  manage_aws_auth_configmap = true

  cluster_addons = {
    coredns = {
      addon_version = "v1.11.1-eksbuild.9"
    }
    kube-proxy = {
      addon_version = "v1.30.0-eksbuild.3"
    }
    vpc-cni = {
      addon_version = "v1.18.2-eksbuild.1"
    }
    metrics-server = {}
    aws-ebs-csi-driver = {}
  }
}
