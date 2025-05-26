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

variable "appstack" {
  type = map(object({
    memory  = string
    cpu     = string
    storage = string
  }))
  description = "Map of resource configurations for different stacks (from .Values.appstack)."
}

variable "selected_stack" {
  type        = string
  description = "The selected stack configuration to use for resources (from .Values.selectedStack)."
  # Example: "small"
}


variable "volume_mounts" {
  description = "List of volume mounts for the container"
  type        = list(object({
    name       = string
    mountPath  = string
    readOnly   = optional(bool)
    subPath    = optional(string)
  }))
  default = []
}

variable "volumes" {
  description = "Volumes used in the pod"
  type        = list(any)
  default     = []
}