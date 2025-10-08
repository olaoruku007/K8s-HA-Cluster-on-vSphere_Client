# vSphere Configuration
variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

variable "allow_unverified_ssl" {
  description = "Allow unverified SSL"
  type        = bool
  default     = true
}

variable "vsphere_datacenter" {
  description = "vSphere datacenter"
  type        = string
}

variable "vsphere_datastore" {
  description = "vSphere datastore"
  type        = string
}

variable "vsphere_cluster" {
  description = "vSphere cluster"
  type        = string
}

variable "vsphere_network" {
  description = "vSphere network"
  type        = string
}

variable "vm_template" {
  description = "Rocky Linux 9.6 template name"
  type        = string
}

# Cluster Configuration
variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "k8s-prod"
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "local"
}

# Network Configuration
variable "network_cidr" {
  description = "Network CIDR"
  type        = string
  default     = "192.168.1.0/24"
}

variable "network_netmask" {
  description = "Network netmask"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Default gateway"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "master_ip_start" {
  description = "Starting IP offset for masters"
  type        = number
  default     = 10
}

variable "worker_ip_start" {
  description = "Starting IP offset for workers"
  type        = number
  default     = 20
}

# Master Node Configuration
variable "master_cpu" {
  description = "Master node CPU count"
  type        = number
  default     = 4
}

variable "master_memory" {
  description = "Master node memory in MB"
  type        = number
  default     = 8192
}

variable "master_disk_size" {
  description = "Master node disk size in GB"
  type        = number
  default     = 100
}

# Worker Node Configuration
variable "worker_cpu" {
  description = "Worker node CPU count"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "Worker node memory in MB"
  type        = number
  default     = 16384
}

variable "worker_disk_size" {
  description = "Worker node disk size in GB"
  type        = number
  default     = 200
}

variable "ssh_user" {
  description = "SSH user for Ansible"
  type        = string
  default     = "root"
}
