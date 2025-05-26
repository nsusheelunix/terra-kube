name = "application"
env1 = "dev"
autoscaling_enabled = "true"
replicacount = "1"
imgurl = "nginx:latest"
selected_stack = "small"
appstack = {
  small = { memory = "512Mi", cpu = "250m", storage = "1Gi" }
  medium = { memory = "1Gi", cpu = "500m", storage = "5Gi" }
}

volume_mounts = [
  {
    name       = "data-volume"
    mount_path = "/data"
  }
]

volumes = [
    {
      name     = "data"
      emptyDir = {}
    }
  ]




     