# K8s-HA-Cluster-on-vSphere_Client

# Kubernetes HA Cluster on vSphere with Rocky Linux 9.6

Complete infrastructure-as-code solution for deploying a highly-available Kubernetes cluster on VMware vSphere using Terraform and Ansible.

## Architecture

- **3 Master Nodes**: Control plane with HA configuration
- **3 Worker Nodes**: Workload execution nodes
- **OS**: Rocky Linux 9.6
- **Container Runtime**: containerd
- **CNI**: Calico (configurable to Flannel or Weave)
- **Orchestration**: kubeadm

## Prerequisites

### Local Machine Requirements

1. **Terraform** >= 1.0
   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.4/terraform_1.6.4_linux_amd64.zip
   unzip terraform_1.6.4_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Ansible** >= 2.14
   ```bash
   # Install Ansible
   sudo dnf install ansible-core -y
   # or
   pip3 install ansible
   ```

3. **SSH Key Pair**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s_rsa
   ```

### vSphere Requirements

1. **Rocky Linux 9.6 Template**: Create a VM template with:
   - Rocky Linux 9.6 minimal installation
   - VMware Tools or open-vm-tools installed
   - SSH enabled
   - Root access or sudo user configured
   - Cloud-init or customization support enabled

2. **vSphere Resources**:
   - Datacenter
   - Compute Cluster
   - Datastore (minimum 900 GB free)
   - Network with DHCP or static IP range
   - User with VM provisioning permissions

3. **Network Requirements**:
   - 6 available IP addresses (3 masters + 3 workers)
   - 1 optional VIP for load balancer
   - Outbound internet access for package downloads

## Directory Structure

```
.
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── templates/
│       └── inventory.tpl
└── ansible/
    ├── site.yml
    ├── ansible.cfg
    ├── inventory/
    │   └── hosts.ini
    ├── group_vars/
    │   └── all.yml
    └── roles/
        ├── common/
        │   ├── tasks/
        │   │   └── main.yml
        │   └── templates/
        │       └── hosts.j2
        ├── container-runtime/
        │   └── tasks/
        │       └── main.yml
        ├── kubernetes-packages/
        │   └── tasks/
        │       └── main.yml
        ├── kubernetes-master-init/
        │   └── tasks/
        │       └── main.yml
        ├── kubernetes-master-join/
        │   └── tasks/
        │       └── main.yml
        ├── kubernetes-worker-join/
        │   └── tasks/
        │       └── main.yml
        └── kubernetes-networking/
            └── tasks/
                └── main.yml
```

## Deployment Steps

### Step 1: Prepare Rocky Linux 9.6 Template

```bash
# On the template VM, install basic tools
sudo dnf update -y
sudo dnf install -y open-vm-tools cloud-init perl

# Enable SSH
sudo systemctl enable sshd
sudo systemctl start sshd

# Allow root login or configure sudo user
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Install your SSH public key
mkdir -p /root/.ssh
echo "your-ssh-public-key" >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Clean up before template conversion
sudo dnf clean all
sudo rm -rf /tmp/*
sudo history -c
```

Convert the VM to a template in vCenter.

### Step 2: Configure Terraform

1. **Create terraform.tfvars**:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

2. **Edit terraform.tfvars** with your values:
```hcl
vsphere_user       = "administrator@vsphere.local"
vsphere_password   = "YourSecurePassword"
vsphere_server     = "vcenter.yourdomain.com"
vsphere_datacenter = "YourDatacenter"
vsphere_datastore  = "YourDatastore"
vsphere_cluster    = "YourCluster"
vsphere_network    = "VM Network"
vm_template        = "rocky-linux-9.6-template"

cluster_name    = "k8s-prod"
network_cidr    = "192.168.100.0/24"
gateway         = "192.168.100.1"
dns_servers     = ["8.8.8.8", "8.8.4.4"]
master_ip_start = 10  # IPs: .10, .11, .12
worker_ip_start = 20  # IPs: .20, .21, .22
```

3. **Deploy Infrastructure**:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

4. **Verify deployment**:
```bash
terraform output
```

### Step 3: Configure Ansible

1. **Update Ansible inventory** (if not auto-generated):
```bash
cd ../ansible
cp inventory/hosts.ini.example inventory/hosts.ini
# Edit with your actual IPs from Terraform output
```

2. **Configure variables**:
Edit `group_vars/all.yml`:
```yaml
kubernetes_version: "1.28"
kubernetes_cni: "calico"
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"
control_plane_endpoint: "192.168.100.10:6443"  # First master or LB VIP
```

3. **Test connectivity**:
```bash
ansible all -m ping
```

### Step 4: Deploy Kubernetes

1. **Run the playbook**:
```bash
ansible-playbook -i inventory/hosts.ini site.yml
```

The playbook will:
- Configure all nodes with required system settings
- Install containerd runtime
- Install Kubernetes packages (kubeadm, kubelet, kubectl)
- Initialize the first master node
- Join additional master nodes
- Join worker nodes
- Deploy CNI network plugin
- Verify cluster health

2. **Monitor deployment**:
```bash
# The playbook shows progress for each role
# Total time: ~15-20 minutes depending on network speed
```

### Step 5: Verify Cluster

1. **SSH to first master**:
```bash
ssh root@192.168.100.10
```

2. **Check cluster status**:
```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

3. **Expected output**:
```
NAME                STATUS   ROLES           AGE   VERSION
k8s-prod-master-1   Ready    control-plane   10m   v1.28.x
k8s-prod-master-2   Ready    control-plane   8m    v1.28.x
k8s-prod-master-3   Ready    control-plane   8m    v1.28.x
k8s-prod-worker-1   Ready    <none>          5m    v1.28.x
k8s-prod-worker-2   Ready    <none>          5m    v1.28.x
k8s-prod-worker-3   Ready    <none>          5m    v1.28.x
```

### Step 6: Configure kubectl on Local Machine

```bash
# Copy kubeconfig from master
scp root@192.168.100.10:/etc/kubernetes/admin.conf ~/.kube/config

# Test access
kubectl get nodes
```

## Configuration Options

### Change CNI Plugin

Edit `ansible/group_vars/all.yml`:
```yaml
kubernetes_cni: "flannel"  # Options: calico, flannel, weave
```

### Adjust Resource Allocation

Edit `terraform/terraform.tfvars`:
```hcl
master_cpu    = 4
master_memory = 8192  # MB
master_disk_size = 100  # GB

worker_cpu    = 8
worker_memory = 32768
worker_disk_size = 500
```

### Add More Nodes

1. **Edit Terraform**:
```hcl
# In main.tf, change count
resource "vsphere_virtual_machine" "k8s_worker" {
  count = 5  # Change from 3 to 5
  ...
}
```

2. **Apply changes**:
```bash
terraform apply
```

3. **Update inventory and run worker join role**:
```bash
ansible-playbook -i inventory/hosts.ini site.yml --tags worker-join
```

## Load Balancer (Recommended for Production)

For production HA, add a load balancer in front of master nodes:

### Option 1: HAProxy + Keepalived

Deploy 2 additional VMs with HAProxy:
```bash
# HAProxy configuration
frontend k8s_api
    bind *:6443
    mode tcp
    option tcplog
    default_backend k8s_masters

backend k8s_masters
    mode tcp
    balance roundrobin
    server master1 192.168.100.10:6443 check
    server master2 192.168.100.11:6443 check
    server master3 192.168.100.12:6443 check
```

Update `control_plane_endpoint` to LB VIP:
```yaml
control_plane_endpoint: "192.168.100.100:6443"
```

### Option 2: NSX-T Load Balancer

Use vSphere NSX-T to create a load balancer for the API server.

## Troubleshooting

### Nodes Not Ready

```bash
# Check kubelet status
systemctl status kubelet
journalctl -xeu kubelet

# Check CNI pods
kubectl get pods -n kube-system | grep -E 'calico|flannel'
```

### Join Command Issues

```bash
# Regenerate join commands on first master
kubeadm token create --print-join-command

# For control plane nodes
kubeadm token create --print-join-command \
  --certificate-key $(kubeadm init phase upload-certs --upload-certs | tail -1)
```

### Network Issues

```bash
# Verify pod network CIDR doesn't overlap with node network
# Check firewall rules
firewall-cmd --list-all

# Verify kernel modules
lsmod | grep br_netfilter
lsmod | grep overlay
```

### Terraform Issues

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Force recreate a VM
terraform taint vsphere_virtual_machine.k8s_master[0]
terraform apply
```

## Maintenance

### Update Kubernetes

```bash
# On each node, starting with masters
dnf update kubeadm
kubeadm upgrade plan
kubeadm upgrade apply v1.29.0
dnf update kubelet kubectl
systemctl restart kubelet
```

### Backup etcd

```bash
# On master node
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /backup/etcd-snapshot.db
```

## Cleanup

### Remove Cluster

```bash
# Ansible - reset nodes (optional)
ansible all -m shell -a "kubeadm reset -f"

# Terraform - destroy infrastructure
cd terraform
terraform destroy -auto-approve
```

## Security Considerations

1. **Change default credentials** immediately
2. **Use SSH keys** instead of passwords
3. **Implement RBAC** policies
4. **Enable Pod Security Standards**
5. **Regular updates** for OS and Kubernetes
6. **Network policies** to restrict pod communication
7. **Encrypt etcd** data at rest
8. **Use secrets management** (e.g., Vault, Sealed Secrets)

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Rocky Linux Documentation](https://docs.rockylinux.org/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/about)

## Support

For issues:
1. Check logs: `journalctl -xeu kubelet`
2. Verify network connectivity
3. Review Ansible playbook output
4. Check vSphere events for VM issues

## License

MIT License - Use at your own risk
