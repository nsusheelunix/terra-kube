# GKE App Deployment Terraform Module

This module provisions a full Kubernetes deployment on GKE, including:

- Namespace
- ConfigMap
- ServiceAccount
- Deployment with dynamic resources
- Service (internal)
- Ingress (HTTPS)
- BackendConfig and FrontendConfig
- Horizontal Pod Autoscaler (HPA)

## Usage

```hcl
module "app" {
  source = "./gke-app-deployment"

  name                = "testingapp"
  env1                = "production"
  imgurl              = "nginx:latest"
  autoscaling_enabled = true
  replicacount        = 2
  selected_stack      = "medium"

  appstack = {
    small = {
      memory  = "256Mi"
      cpu     = "250m"
      storage = "500Mi"
    }
    medium = {
      memory  = "512Mi"
      cpu     = "500m"
      storage = "1Gi"
    }
  }

  volume_mounts = [
    {
      name      = "data"
      mountPath = "/data"
    }
  ]

  volumes = [
    {
      name     = "data"
      emptyDir = {}
    }
  ]
}
