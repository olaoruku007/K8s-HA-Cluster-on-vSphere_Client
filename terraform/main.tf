terraform {
  required_version = ">= 1.0"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.5"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Master Nodes
resource "vsphere_virtual_machine" "k8s_master" {
  count            = 3
  name             = "${var.cluster_name}-master-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.master_cpu
  memory           = var.master_memory
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.master_disk_size
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "${var.cluster_name}-master-${count.index + 1}"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = cidrhost(var.network_cidr, var.master_ip_start + count.index)
        ipv4_netmask = var.network_netmask
      }

      ipv4_gateway    = var.gateway
      dns_server_list = var.dns_servers
    }
  }
}

# Worker Nodes
resource "vsphere_virtual_machine" "k8s_worker" {
  count            = 3
  name             = "${var.cluster_name}-worker-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.worker_cpu
  memory           = var.worker_memory
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.worker_disk_size
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "${var.cluster_name}-worker-${count.index + 1}"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = cidrhost(var.network_cidr, var.worker_ip_start + count.index)
        ipv4_netmask = var.network_netmask
      }

      ipv4_gateway    = var.gateway
      dns_server_list = var.dns_servers
    }
  }
}
