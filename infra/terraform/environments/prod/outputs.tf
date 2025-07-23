# Production Environment Outputs

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = module.eks_cluster.db_instance_address
}

output "db_port" {
  description = "Database port"
  value       = module.eks_cluster.db_instance_port
}
