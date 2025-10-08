# Copy this file to terraform.tfvars and fill in your values

# vSphere Configuration
vsphere_user       = "administrator@vsphere.local"
vsphere_password   = "YourPassword"
vsphere_server     = "vcenter.example.com"
vsphere_datacenter = "Datacenter"
vsphere_datastore  = "Datastore1"
vsphere_cluster    = "Cluster1"
vsphere_network    = "VM Network"
vm_template        = "rocky-linux-9.6-template"

# Cluster Configuration
cluster_name = "k8s-prod"
domain       = "k8s.local"

# Network Configuration
network_cidr    = "192.168.1.0/24"
network_netmask = 24
gateway         = "192.168.1.1"
dns_servers     = ["8.8.8.8", "8.8.4.4"]
master_ip_start = 10  # Masters will be .10, .11, .12
worker_ip_start = 20  # Workers will be .20, .21, .22

# SSH Configuration
ssh_user = "root"
