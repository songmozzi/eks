output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
}

output "node_group_iam_role_arn" {
  value       = module.eks.node_groups["eks_nodes"].iam_role_arn
}
