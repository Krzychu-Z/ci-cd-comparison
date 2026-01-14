data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
  cluster_name = var.cluster_name
}

# ========= VPC: public + private + single NAT =========
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = "${local.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs = local.azs

  # Public subnets (for NAT GW, public load balancers, bastion, etc.)
  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]

  # Private subnets (for EKS worker nodes)
  private_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24",
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  # Optional but nice: tag subnets for Kubernetes LB controller
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ========= EKS cluster + on-demand nodes in private subnets =========
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = "1.33"

  # Public endpoint for simplicity (nodes talk via private subnets + NAT)
  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  vpc_id = module.vpc.vpc_id

  # Use private subnets for the cluster and worker nodes
  subnet_ids = module.vpc.private_subnets

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    spot-ng = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.instance_type]

      # spot capacity
      capacity_type = "SPOT"

      min_size     = 4
      max_size     = 4
      desired_size = 4

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100          # 100 GiB root disk
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      }

      subnet_ids = module.vpc.private_subnets

      # Optional: allow SSH via your key (and a bastion / SSM)
      # remote_access = {
      #   ec2_ssh_key = "my-keypair"
      # }
    }
  }

  tags = {
    Environment = "scratch"
    Terraform   = "true"
  }
}