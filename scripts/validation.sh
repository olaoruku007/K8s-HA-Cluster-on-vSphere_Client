# ====================
# scripts/validate.sh - Validation script
# ====================
#!/bin/bash

echo "=== Kubernetes Cluster Validation ==="
echo ""

MASTER_IP=$(cd terraform && terraform output -json master_ips | jq -r '.[0]')

if [ -z "$MASTER_IP" ]; then
    echo "Error: Could not get master IP from Terraform output"
    exit 1
fi

echo "Master IP: $MASTER_IP"
echo ""

# Test SSH connectivity
echo "1. Testing SSH connectivity..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$MASTER_IP "echo 'SSH connection successful'" || {
    echo "Failed to connect via SSH"
    exit 1
}

# Check cluster nodes
echo ""
echo "2. Checking cluster nodes..."
ssh root@$MASTER_IP "kubectl get nodes" || {
    echo "Failed to get node status"
    exit 1
}

# Check system pods
echo ""
echo "3. Checking system pods..."
ssh root@$MASTER_IP "kubectl get pods -n kube-system"

# Check cluster info
echo ""
echo "4. Cluster information..."
ssh root@$MASTER_IP "kubectl cluster-info"

# Check component status
echo ""
echo "5. Component status..."
ssh root@$MASTER_IP "kubectl get cs" 2>/dev/null || echo "Component status deprecated in newer versions"

echo ""
echo "=== Validation Complete ==="
