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

# 서브넷 생성 (Pod 전용 서브넷 포함)
resource "aws_subnet" "eks_subnet" {
  count                = 2
  vpc_id               = aws_vpc.eks_vpc.id
  cidr_block           = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  availability_zone    = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

resource "aws_subnet" "pod_subnet" {
  count                = 1
  vpc_id               = aws_vpc.eks_vpc.id
  cidr_block           = "10.1.0.0/24"
  availability_zone    = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "pod-subnet"
  }
}

# EKS 클러스터 및 노드 그룹 생성
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.30"
  subnets         = concat(aws_subnet.eks_subnet[*].id, aws_subnet.pod_subnet[*].id)
  vpc_id          = aws_vpc.eks_vpc.id

  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.medium"
    }
  }

  manage_aws_auth = true

  eks_addons = {
    coredns = {
      addon_name    = "coredns"
      addon_version = "v1.11.1-eksbuild.9"
    }
    kube-proxy = {
      addon_name    = "kube-proxy"
      addon_version = "v1.30.0-eksbuild.3"
    }
    vpc-cni = {
      addon_name    = "vpc-cni"
      addon_version = "v1.18.2-eksbuild.1"
    }
    metrics-server = {
      addon_name    = "metrics-server"
      addon_version = "latest"
    }
    aws-ebs-csi-driver = {
      addon_name    = "aws-ebs-csi-driver"
      addon_version = "latest"
    }
  }
}
