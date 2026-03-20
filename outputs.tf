output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_name" {
    value = module.eks.cluster_name 
}

output "cluster_id" {
  value = module.eks.cluster_id
}