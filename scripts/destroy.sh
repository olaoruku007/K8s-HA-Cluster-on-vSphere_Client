# ====================
# scripts/destroy.sh - Cleanup script
# ====================
#!/bin/bash
set -e

echo "=== Kubernetes Cluster Cleanup ==="
echo ""
echo "WARNING: This will destroy all resources!"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Optional: Reset Kubernetes nodes
echo ""
read -p "Do you want to reset Kubernetes on nodes first? (yes/no): " reset_k8s

if [ "$reset_k8s" == "yes" ]; then
    echo "Resetting Kubernetes on all nodes..."
    cd ansible
    ansible all -b -m shell -a "kubeadm reset -f && rm -rf /etc/cni/net.d/* && rm -rf /var/lib/etcd/*" || echo "Some nodes may have failed to reset"
    cd ..
fi

# Destroy infrastructure
echo ""
echo "Destroying Terraform infrastructure..."
cd terraform
terraform destroy -auto-approve

echo ""
echo "=== Cleanup Complete ==="
