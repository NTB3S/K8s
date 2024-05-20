# Free Oracle Cloud Kubernetes Cluster Setup Guide

## Oracle Cloud Setup

### Oracle Cloud Instances Creation
With Oracle Cloud's free plan, you can create at least **two ARM instances**. For this setup, we'll create two instances with the following specifications:
- **Canonical Ubuntu 22.04**
- **2 OCPU**
- **12 GB Memory**

By default, your instance will have an ephemeral public address. To switch between ephemeral and public IP addresses, navigate to:
```
Instances > Instance Details > Attached VNICs > VNIC Details > IPv4 address
```
Select **NO PUBLIC IP**, confirm it, and then the PUBLIC IP should be available.

### Oracle Cloud VNC Configuration
To access your cluster, you need to define some ingress rules.

1. **Enable SSH Access**: Open port 22 to allow SSH access from your workstation.
2. **Inter-Instance Communication**: Enable connection between instances in your VNC. You can open all ports or specify the required ports based on Kubernetes documentation: [Kubernetes Networking](https://kubernetes.io/docs/reference/networking/ports-and-protocols/).
3. **HTTP Access**: Open port 80 to access it from any browser.

### Firewall Configuration
Each new Oracle Cloud instance has a default firewall configuration. To ensure your cluster operates correctly, you need to adjust some rules.

Run the `./setup-nodes/firewallSetup.sh` script or execute the following instructions:
```sh
## Save existing rules
sudo iptables-save > ~/iptables-rules

## Modify rules, remove drop and reject lines
grep -v "DROP" iptables-rules > tmpfile && mv tmpfile iptables-rules-mod
grep -v "REJECT" iptables-rules-mod > tmpfile && mv tmpfile iptables-rules-mod

## Apply the modifications
sudo iptables-restore < ~/iptables-rules-mod
## Check
sudo iptables -L

## Save the changes
sudo netfilter-persistent save
sudo systemctl restart iptables
```

## Node Setup
**Perform the following steps on every node of your cluster.**

### Cluster Bootstrapping
Before setting up a cluster with CRI-O, ensure you follow these requirements: enable kernel modules, configure sysctl settings, and disable swap. Refer to the [Kubernetes official documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin).

Run the `./setup-nodes/bootstrapCluster.sh` script or execute the following commands:
```sh
## Disable swap
sudo swapoff -a
sed -i '/swap/d' /etc/fstab

## Kernel configuration
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

## Sysctl parameters required by setup, persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

## Apply sysctl parameters without reboot
sudo sysctl --system
```

### Container Runtime
In Kubernetes, a container runtime manages the lifecycle of containers. We will use CRI-O. Refer to the [Kubernetes runtime setup documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime).

Run the `./setup-nodes/installCrio.sh` script or execute the following commands:
```sh
sudo apt-get update -y
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o

sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service
```

### Kubeadm, Kubelet, and Kubectl
After installing CRI-O, install the Kubernetes components: kubeadm, kubelet, and kubectl.

Run the `./setup-nodes/installK8s.sh` script or execute the following commands:
```sh
KUBERNETES_VERSION=v1.30
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
```

## Control plane Setup
### Kubeadm Init
Initialize the Kubernetes cluster on the control plane by setting up the master node:
```sh
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

Create the kubeconfig file to interact with the cluster API:
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Verify the kubeconfig:
```sh
kubectl get po -n kube-system
```

Check the cluster component health status:
```sh
kubectl get --raw='/readyz?verbose'
```

To allow scheduling on the master node:
```sh
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### Join Worker Nodes to Master Node
Join the worker node to the master node using the Kubeadm join command:
```sh
kubeadm token create --print-join-command
```

Execute the join command on the worker node:
```sh
sudo kubeadm join <master-node-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

Check the node status from the master node:
```sh
kubectl get nodes
```

## Helm
Helm is a package manager for Kubernetes, simplifying the deployment and management of applications within your cluster. It uses charts to define, install, and upgrade even the most complex Kubernetes applications.

Install Helm based on your package manager instructions: [Helm Installation](https://helm.sh/docs/intro/install/).

## Addons
The following steps are performed on the control plane node.

### CNI - Calico
Calico is a Container Network Interface (CNI) plugin providing scalable networking and network policy management for Kubernetes clusters. It supports a range of networking options and ensures secure, high-performance networking for your cluster.

To install Calico, follow the commands below:
```sh
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml -O
kubectl apply -f calico.yaml
```

### LoadBalancer - MetalLB
MetalLB is a load balancer implementation for bare-metal Kubernetes clusters, providing the ability to assign external IPs to services in the same way as cloud-native solutions. It integrates seamlessly with standard network equipment to ensure that external services work reliably.

To install MetalLB, execute the following commands:
```sh
kubectl apply -f metallb/metallb-calico.yaml
```

The installation manifest does not include a configuration file. While MetalLB's components will start, they will remain idle until we provide the required configuration, including an IPAddressPool.
We'll be employing Layer 2 configuration for simplicity. This mode requires only a range of IP addresses. As detailed in the official documentation [here](https://metallb.universe.tf/configuration/), we'll need to create an additional manifest to provision an object of type L2Advertisement.

Run the following commands
```
kubectl apply -f metallb/ipaddresspool.yaml
kubectl apply -f metallb/l2advertisement.yaml
```

### Ingress - Nginx
An Ingress controller is an essential component for managing external access to your services in a Kubernetes cluster, typically via HTTP/HTTPS. It provides capabilities such as load balancing, SSL termination, and name-based virtual hosting. The Nginx Ingress Controller is a popular choice for managing these requirements due to its performance, reliability, and comprehensive feature set.

To install the Nginx Ingress Controller:

1. Download and unpack the Helm chart:
    ```sh
    helm pull oci://ghcr.io/nginxinc/charts/nginx-ingress --untar --version 1.2.1
    ```
2. Apply the necessary Custom Resource Definitions (CRDs):
    ```sh
    kubectl apply -f nginx-ingress/crds/
    ```

Before installing, update the `values.yaml` with the following modifications:
- Set `hostPort` to **true**.
- Set `kind` to **DaemonSet**.

3. Install the Nginx Ingress Controller using Helm:
    ```sh
    helm install nginx-ingress nginx-ingress
    ```

### Reset Your Cluster
To reset your cluster, run the `./setup-nodes/resetCluster.sh` script or use the following commands:
```sh
kubeadm reset -f
sudo iptables-restore < ~/iptables-rules-mod

sudo netfilter-persistent save
sudo systemctl restart iptables
```

### Sources
- [DevOpsCube Kubernetes Setup](https://devopscube.com/setup-kubernetes-cluster-kubeadm/)
- [Kubernetes Documentation](https://kubernetes.io/)
- [Earthly CRI-O Kubernetes Deployment](https://earthly.dev/blog/deploy-kubernetes-cri-o-container-runtime/)
- [Oracle Cloud Kubernetes Guide](https://medium.com/@ekeneejike/kubernetes-install-guide-using-kubeadm-on-oracle-cloud-for-free-)
