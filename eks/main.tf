// EKS VPC
resource "aws_vpc" "eks" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "EKS VPC"
  }
}

// EKS VPC Public Subnets
resource "aws_subnet" "eks_public" {
  for_each = var.eks_public_subnet_cidrs

  vpc_id            = aws_vpc.eks.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "EKS VPC Public Subnet - ${each.key}"
  }
}

// EKS VPC Private Subnets
resource "aws_subnet" "eks_private" {
  for_each = var.eks_private_subnet_cidrs

  vpc_id            = aws_vpc.eks.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "EKS VPC Private Subnet - ${each.key}"
  }
}

// EKS VPC Internet Gateway
resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "EKS VPC Internet Gateway"
  }
}

// EKS VPC NAT Gateway & EIP
resource "aws_eip" "eks_ngw" {
  domain = "vpc"

  tags = {
    Name = "EKS VPC NAT Gateway EIP"
  }
}

resource "aws_nat_gateway" "eks" {
  allocation_id = aws_eip.eks_ngw.id
  subnet_id     = aws_subnet.eks_public["us-east-1a"].id

  depends_on = [aws_internet_gateway.eks]

  tags = {
    Name = "EKS VPC NAT Gateway"
  }
}

// EKS VPC Public Route Table & Routes
resource "aws_route_table" "eks_public" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "EKS VPC Public Route Table"
  }
}

resource "aws_route" "eks_public_igw" {
  route_table_id         = aws_route_table.eks_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks.id
}

resource "aws_route_table_association" "eks_public" {
  for_each = { for name, subnet in aws_subnet.eks_public : name => subnet }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.eks_public.id
}

// EKS VPC Private Route Table & Routes
resource "aws_route_table" "eks_private" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "EKS VPC Private Route Table"
  }
}

resource "aws_route" "eks_private_ngw" {
  route_table_id         = aws_route_table.eks_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks.id
}

resource "aws_route_table_association" "eks_private" {
  for_each = { for name, subnet in aws_subnet.eks_private : name => subnet }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.eks_private.id
}

// EKS Cluster IAM Role
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_assume_role" {
  name               = "eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_assume_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_assume_role.name
}

// EKS Cluster
resource "aws_eks_cluster" "bentest" {
  name     = "bentest"
  role_arn = aws_iam_role.eks_assume_role.arn

  vpc_config {
    subnet_ids = concat(
      [for subnet in aws_subnet.eks_public : subnet.id],
      [for subnet in aws_subnet.eks_private : subnet.id]
    )
  }

  // Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  // Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}
