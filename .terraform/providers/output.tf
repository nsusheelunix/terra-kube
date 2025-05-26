output "deployment_name" {
  description = "The name of the Kubernetes deployment."
  value       = kubernetes_deployment.app_deployment.metadata[0].name
}
output "namespace" {
  description = "The name of the Kubernetes namespace for the application"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}
output "service_name" {
  value = kubernetes_service.app_service.metadata[0].name
}

output "ingress_url" {
  description = "The URL of the Kubernetes ingress for the application."
  value       = "https://${kubernetes_ingress_v1.app_ingress.metadata[0].name}.${var.name}"
} 
