output "master_ips" {
  description = "Master node IP addresses"
  value = [
    for vm in vsphere_virtual_machine.k8s_master : 
    vm.default_ip_address
  ]
}

output "worker_ips" {
  description = "Worker node IP addresses"
  value = [
    for vm in vsphere_virtual_machine.k8s_worker : 
    vm.default_ip_address
  ]
}

output "master_names" {
  description = "Master node names"
  value       = vsphere_virtual_machine.k8s_master[*].name
}

output "worker_names" {
  description = "Worker node names"
  value       = vsphere_virtual_machine.k8s_worker[*].name
}

