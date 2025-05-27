name = "application"
env1 = "dev"
autoscaling_enabled = "true"
replicacount = "1"
imgurl = "nginx:latest"
service_port = 80
service_type = "ClusterIP"
pvc_size             = "1Gi"
storage_class_name   = "standard"
secret_value         = "mysecretvalue"
selected_stack = "small"
container_port = 8080
appstack = {
  small = { memory = "512Mi", cpu = "250m", storage = "1Gi" }
  medium = { memory = "1Gi", cpu = "500m", storage = "5Gi" }
}




     