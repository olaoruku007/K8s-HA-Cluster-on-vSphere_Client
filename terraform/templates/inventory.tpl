# ====================
# terraform/templates/inventory.tpl
# ====================
[masters]
%{ for idx, node in master_nodes ~}
${node.name} ansible_host=${node.default_ip_address}
%{ endfor ~}

[workers]
%{ for idx, node in worker_nodes ~}
${node.name} ansible_host=${node.default_ip_address}
%{ endfor ~}

[k8s_cluster:children]
masters
workers

[all:vars]
ansible_user=${ssh_user}
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

# ====================
# Makefile (Optional helper)
# ====================
.PHONY: help plan apply destroy ansible-ping ansible-deploy

help:
	@echo "Available targets:"
	@echo "  plan           - Show Terraform execution plan"
	@echo "  apply          - Deploy infrastructure with Terraform"
	@echo "  destroy        - Destroy infrastructure"
	@echo "  ansible-ping   - Test Ansible connectivity"
	@echo "  ansible-deploy - Deploy Kubernetes with Ansible"
	@echo "  full-deploy    - Complete deployment (Terraform + Ansible)"

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

destroy:
	cd terraform && terraform destroy

ansible-ping:
	cd ansible && ansible all -m ping

ansible-deploy:
	cd ansible && ansible-playbook -i inventory/hosts.ini site.yml

full-deploy: apply
	@echo "Waiting 60 seconds for VMs to fully initialize..."
	@sleep 60
	@echo "Testing connectivity..."
	cd ansible && ansible all -m ping
	@echo "Deploying Kubernetes cluster..."
	cd ansible && ansible-playbook -i inventory/hosts.ini site.yml

