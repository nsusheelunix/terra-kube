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
resource "kubernetes_namespace" "testingapp_namespace" {
  metadata {
    name = "test-app"
  }
}

###############################################################################################
# ConfigMap
resource "kubernetes_config_map" "testingapp_configmap" {
  metadata {
    name      = "testingapp-configmap"
    namespace = kubernetes_namespace.testingapp_namespace.metadata[0].name
  }
  data = {
    application_profile = "dev"
  }
}

################################################################################################
# Deployment
resource "kubernetes_deployment" "testingapp_deployment" {
  metadata {
    name      = "testingapp-deployment"
    namespace = kubernetes_namespace.testingapp_namespace.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        testingapp = "my-testingapp"
      }
    }
    template {
      metadata {
        labels = {
          testingapp = "my-testingapp"
        }
      }
      spec {
        container {
          name  = "my-testingapp"
          image = "europe-west3-docker.pkg.dev/cp-mat-poc-moc-44ac5eea78b4a8e/mat-tool/mat-tool:0.0.4"
          port {
            container_port = 8080
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.testingapp_configmap.metadata[0].name
            }
          }
        }
      }
    }
  }
}

############################################################################################################### 
# Service
resource "kubernetes_service" "testingapp_service" {
  metadata {
    name      = "testingapp-service"
    namespace = kubernetes_namespace.testingapp_namespace.metadata[0].name
    annotations = {
      "networking.gke.io/app-protocols"      = jsonencode({"http" = "HTTP"})
      "cloud.google.com/backend-config"       = jsonencode({"default" = "testingapp_backend_config"})
      "networking.gke.io/load-balancer-type" = "Internal"
      "cloud.google.com/neg"                  = jsonencode({"ingress" = true})
    }
  }
  spec {
    selector = {
      testingapp = "my-testingapp"
    }
    port {
      port = 443
    }
    type = "ClusterIP"
  }
}

#################################################################################################################
# Ingress
resource "kubernetes_ingress_v1" "testingapp_ingress" {
  metadata {
    name      = "testingapp-ingress"
    namespace = kubernetes_namespace.testingapp_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                     = "gce-internal"
      "networking.gke.io/internal-load-balancer-allow-global-access" = "true"
      "cloud.google.com/backend-config"                  = jsonencode({"default" = "testingapp_backend_config"})
      "ingress.kubernetes.io/backend-protocol"          = "HTTP"
      "kubernetes.io/ingress.allow-http"                = "false"
      "ingress.gcp.kubernetes.io/pre-shared-cert"      = "poc-moc-cpdnb-net"
    }
  }
  spec {
    default_backend {
      service {
        name = "testingapp-service"
        port {
          number = 443
        }
      }
    }
  }
}

#########################################################################################
# Service Account
resource "kubernetes_service_account" "testingapp_sa" {
  metadata {
    name      = "testingapp-service-account"
    namespace = kubernetes_namespace.testingapp_namespace.metadata[0].name
  }
}

#######################################################################################
# BackendConfig
resource "kubernetes_manifest" "testingapp_backend_config" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "testingapp_backend_config"
      namespace = kubernetes_namespace.testingapp_namespace.metadata[0].name
    }
    spec = {
      connectionDraining = {
        drainingTimeoutSec = 300
      }
      healthCheck = {
        checkIntervalSec = 30
        healthyThreshold   = 1
        port              = 8080
        requestPath       = "/"
        timeoutSec        = 10
        type              = "HTTP"
        unhealthyThreshold = 3
      }
    }
  }
}

################################################################################################
# FrontendConfig
resource "kubernetes_manifest" "testingapp_frontendConfig" {
  manifest = {
    apiVersion = "networking.gke.io/v1beta1"
    kind       = "FrontendConfig"
    metadata = {
      name      = "testingapp_frontendconfig"
      namespace = kubernetes_namespace.testingapp_namespace.metadata[0].name
    }
    spec = {
      sslPolicy     = "poc-moc-cpdnb-net"
      redirectToHttps = {
        enabled = true
      }
    }
  }
}

#####################################################################################################
# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler" "testingapp_hpa" {
  metadata {
    name      = "testingapp-hpa"
    namespace = kubernetes_namespace.testingapp_namespace.metadata[0].name  
  }

  spec {
    scale_target_ref {
      name        = "testingapp-deployment"
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
          type              = "Utilization" 
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