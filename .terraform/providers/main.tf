terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config" # Path to your kubeconfig file
}

#############################################################################################
# Namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.name
  }
}

###############################################################################################
# ConfigMap
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.name}-configmap"
    namespace = var.name
  }

  data = {
    application_profile = var.env1
  }
}


################################################################################################
# Deployment
resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name      = "${var.name}-deployment"
    namespace = var.name
  }

  spec {
    replicas = var.autoscaling_enabled ? null : var.replicacount

    selector {
      match_labels = {
        app = var.name
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }

        annotations = {
          "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
        }
      }

      spec {
        service_account_name = "${var.name}-sa"

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"

          label_selector {
            match_labels = {
              app = var.name
            }
          }
        }

        container {
          name  = var.name
          image = var.imgurl
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }
          env {
            name = "APPLICATION_PROFILE"
            value_from {
              config_map_key_ref {
                name = "${var.name}-configmap"
                key  = "application_profile"
              }
            }
          }

          dynamic "resources" {
            for_each = var.selected_stack != null && var.appstack[var.selected_stack] != null ? [var.appstack[var.selected_stack]] : []

            content {
              requests = {
                memory              = resources.value.memory
                cpu                 = resources.value.cpu
                "ephemeral-storage" = resources.value.storage
              }

              limits = {
                memory              = resources.value.memory
                cpu                 = resources.value.cpu
                "ephemeral-storage" = resources.value.storage
              }
            }
          }


        dynamic "volume_mount" {
            for_each = var.volume_mounts
            content {
                    name       = volume_mount.value.name
                    mount_path = volume_mount.value.mountPath
                    read_only  = lookup(volume_mount.value, "readOnly", false)
                    sub_path   = lookup(volume_mount.value, "subPath", null)
                 }
            }
        }
        dynamic "volume" {
            for_each = var.volumes
            content {
                name = volume.value.name
                }
            }
      }
    }
  }
}

############################################################################################################### 
# Service
resource "kubernetes_service" "app_service" {
  metadata {
    name      = "${var.name}-service"
    namespace = var.name
    annotations = {
      "networking.gke.io/app-protocols"      = jsonencode({"http" = "HTTP"})
      "cloud.google.com/backend-config"       = jsonencode({"default" = "app_backend_config"})
      "networking.gke.io/load-balancer-type" = "Internal"
      "cloud.google.com/neg"                  = jsonencode({"ingress" = true})
    }
  }
  spec {
    selector = {
      app = var.name
    }
    port {
      port = 443
    }
    type = "ClusterIP"
  }
}

#################################################################################################################
# Ingress
resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = "${var.name}-ingress"
    namespace = var.name
    annotations = {
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target"         = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"           = "true"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"     = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"     = "300"
      "nginx.ingress.kubernetes.io/backend-protocol"       = "HTTP"
    }
  }
  spec {
    ingress_class_name = "nginx"  # Ensures NGINX ingress controller handles this

    default_backend {
      service {
        name = "${var.name}-service"
        port {
          number = 443  # Use 80 if your service isn't exposing TLS
        }
      }
    }
  }
}

#########################################################################################
# Service Account
resource "kubernetes_service_account" "app_sa" {
  metadata {
    name      = "${var.name}-sa"
    namespace = var.name
  }
}

#######################################################################################
# BackendConfig - should be used in cloud concepts where health checks and connection draining are required
# Uncomment and modify the following block if you need to set up a BackendConfig for health checks and connection draining
# Uncomment the following block if you need to set up a BackendConfig for health checks and connection draining
#resource "kubernetes_manifest" "app_backend_config" {
#  manifest = {
#    apiVersion = "cloud.google.com/v1"
#    kind       = "BackendConfig"
#      name      = "${var.name}-backend-config"
#    metadata = {
#      namespace = var.name
#    }
#    spec = {
 #       drainingTimeoutSec = 300
##      connectionDraining = {
#      }
#      healthCheck = {
#        checkIntervalSec = 30
#        healthyThreshold   = 1
#        port              = 8080
#        requestPath       = "/"
#        timeoutSec        = 10
#        type              = "HTTP"
#        unhealthyThreshold = 3
#      }
#   }
#  }
#}

################################################################################################
# FrontendConfig - should be used in cloud concepts where SSL termination is required
# Uncomment and modify the following block if you need to set up a FrontendConfig for SSL termination
# Uncomment the following block if you need to set up a FrontendConfig for SSL termination
#resource "kubernetes_manifest" "app_frontendConfig" {
#  manifest = {
#    apiVersion = "networking.gke.io/v1beta1"
#    kind       = "FrontendConfig"
#    metadata = {
#      namespace = var.name
#    }
##      name      = "${var.name}-frontend-config"
#   spec = {
#      sslPolicy     = "" # Replace with your SSL policy name
#      redirectToHttps = {
#        enabled = true
#      }
#    }
#  }
#}

#####################################################################################################
# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler"  "app_hpa" {
  metadata {
    name      = "${var.name}-hpa"
    namespace = var.name 
  }

  spec {
    scale_target_ref {
      name        = "${var.name}-deployment"
      api_version = "apps/v1"
      kind        = "Deployment"
    }
    
    min_replicas = 1
    max_replicas = 2

    metric { 
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type   = "Utilization" 
          average_utilization = 80  
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300 
        policy {
          type  = "Pods" 
          value = 1  
          period_seconds = 60  
        }
      }
    
      scale_up {
        policy {
          type  = "Pods"  
          value = 2  
          period_seconds = 60  
        }
      }
    }
  }
}
#####################################################################################################
# Persistent Volume Claim
resource "kubernetes_persistent_volume_claim" "app_pvc" {
  metadata {
    name      = "${var.name}-pvc"
    namespace = var.name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_size
      }
    }

    storage_class_name = var.storage_class_name
  }
}
#####################################################################################################
# Persistent Volume
resource "kubernetes_persistent_volume" "app_pv" {
  metadata {
    name = "${var.name}-pv"
  }

  spec {
    capacity = {
      storage = var.pvc_size
    }

    access_modes = ["ReadWriteOnce"]

    persistent_volume_reclaim_policy = "Retain"

    storage_class_name = var.storage_class_name

    host_path {
      path = "/mnt/data/${var.name}" # Adjust the path as needed
    }
  }
}
#####################################################################################################
# Secret
resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "${var.name}-secret"
    namespace = var.name
  }

  data = {
    secret_key = base64encode(var.secret_value) # Ensure the secret value is base64 encoded
  }

  type = "Opaque"
}
#####################################################################################################
# Role
resource "kubernetes_role" "app_role" {
  metadata {
    name      = "${var.name}-role"
    namespace = var.name
  }

  rules {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
}
#####################################################################################################
# RoleBinding
resource "kubernetes_role_binding" "app_role_binding" {
  metadata {
    name      = "${var.name}-role-binding"
    namespace = var.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.app_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.app_sa.metadata[0].name
    namespace = var.name
  }
}
#####################################################################################################