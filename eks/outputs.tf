output "eks_vpc_id" {
  value = aws_vpc.eks.id
}

output "eks_vpc_public_subnet_ids" {
  value = [for subnet in aws_subnet.eks_public : subnet.id]
}

output "eks_vpc_private_subnet_ids" {
  value = [for subnet in aws_subnet.eks_private : subnet.id]
}

output "eks_vpc_public_route_table_id" {
  value = aws_route_table.eks_public.id
}

output "eks_vpc_private_route_table_id" {
  value = aws_route_table.eks_public.id
}

output "eks_vpc_igw_id" {
  value = aws_internet_gateway.eks.id
}

output "eks_vpc_ngw_id" {
  value = aws_nat_gateway.eks.id
}

output "eks_cluster_assume_role_arn" {
  value = aws_iam_role.eks_assume_role.arn
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.bentest.endpoint
}
