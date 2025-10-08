#!/bin/bash
set -e

echo "=== Kubernetes Cluster Setup Script ==="
echo ""

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "Ansible is required but not installed. Aborting." >&2; exit 1; }

# Step 1: Setup directory structure
echo "Step 1: Creating directory structure..."
mkdir -p terraform/templates
mkdir -p ansible/{inventory,group_vars,roles/{common,container-runtime,kubernetes-packages,kubernetes-master-init,kubernetes-master-join,kubernetes-worker-join,kubernetes-networking}/{tasks,templates}}

# Step 2: Terraform deployment
echo ""
echo "Step 2: Deploying infrastructure with Terraform..."
cd terraform

if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found. Please create it from terraform.tfvars.example"
    exit 1
fi

terraform init
terraform plan -out=tfplan
echo ""
read -p "Do you want to apply this plan? (yes/no): " confirm

if [ "$confirm" == "yes" ]; then
    terraform apply tfplan
    echo "Infrastructure deployed successfully!"
else
    echo "Deployment cancelled."
    exit 0
fi

# Step 3: Wait for VMs
echo ""
echo "Step 3: Waiting for VMs to initialize (60 seconds)..."
sleep 60

# Step 4: Test connectivity
cd ../ansible
echo ""
echo "Step 4: Testing Ansible connectivity..."
ansible all -m ping

# Step 5: Deploy Kubernetes
echo ""
read -p "Do you want to proceed with Kubernetes deployment? (yes/no): " confirm_k8s

if [ "$confirm_k8s" == "yes" ]; then
    echo "Step 5: Deploying Kubernetes cluster..."
    ansible-playbook -i inventory/hosts.ini site.yml
    
    echo ""
    echo "=== Deployment Complete! ==="
    echo ""
    echo "To access your cluster:"
    echo "1. SSH to master node: ssh root@\$(terraform output -raw master_ips | head -1)"
    echo "2. Run: kubectl get nodes"
    echo ""
    echo "Or copy kubeconfig locally:"
    echo "scp root@\$(terraform output -raw master_ips | head -1):/etc/kubernetes/admin.conf ~/.kube/config"
else
    echo "Kubernetes deployment skipped."
    echo "You can deploy later with: ansible-playbook -i inventory/hosts.ini site.yml"
fi
