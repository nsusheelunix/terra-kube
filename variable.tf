variable "name" {
  description = "The namespace in which the resources will be created."
  type        = string
}

variable "env1" {
  description = "The first environment variable for the application."
  type        = string  
}

variable "autoscaling_enabled" {
  description = "Flag to enable or disable auto-scaling."
  type        = bool
}

variable "replicacount" {
  description = "The number of replicas for the deployment."
  type        = number
}

variable "imgurl" {
  description = "The Docker image URL for the application."
  type        = string
}

variable "service_port" {
  description = "The port on which the service will be exposed."
  type        = number
}

variable "service_type" {
  description = "The type of service to create (e.g., ClusterIP, NodePort, LoadBalancer)."
  type        = string
}


variable "pvc_size" {
  type        = string
  description = "Size of the Persistent Volume Claim"
}

variable "storage_class_name" {
  type        = string
  description = "Storage class name"
}

variable "secret_value" {
  type        = string
  description = "Secret value"
}

variable "container_port" {
  description = "The port the container listens on."
  type        = number
}


variable "appstack" {
  description = "Map of resource configurations (cpu, memory, storage) for different stacks"
  type = map(object({
    cpu     = string
    memory  = string
    storage = string
  }))
  default = {}
}

variable "selected_stack" {
  type        = string
  description = "The selected stack configuration to use for resources (from .Values.selectedStack)."
  # Example: "small"
  default     = null
}


#variable "volumes" {
#  type = list(object({
#    name                  = string
#    persistent_volume_claim = object({
#      claim_name = string
#      read_only  = optional(bool, false)
#    })
#  }))
#  default = [
#    {
#      name = "data-volume"
#        claim_name = "application-pvc"
##      persistent_volume_claim = {
#        read_only  = false
#      }
#    }
#  ]
#}

#variable "volume_mounts" {
#  type = list(object({
#    name      = string
#    mountPath = string
#    readOnly  = optional(bool, false)
# }))
#  default = [
 #   {
 #     name      = "data-volume"
 #     mountPath = "/usr/share/nginx/html"
 #     readOnly  = false
   # }
  #]
#}