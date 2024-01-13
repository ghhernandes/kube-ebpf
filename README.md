# kube-ebpf
Kubernetes and eBPF learning

# Setup

Kubernetes setup with kubeadm and cilium

## Prerequisites

```
apt update
apt install -y apt-transport-https ca-certificates curl gpg
```

disable swap temporarily (make sure swap is disabled in /etc/fstab, systemd.swap after):

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin
```
swapoff -a
```

enable `overlay` and `br_netfilter` modules

```
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
```

sysctl params required by setup. params persist across reboots:

```

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system
```

verify that modules are loaded

```
lsmod | grep br_netfilter
lsmod | grep overlay
```

## containerd setup

install containerd:
```
apt install -y containerd
```

set default containerd configs:
```
mkdir -p /etc/containerd/
containerd config default > /etc/containerd/config.toml
```

use systemd cgroups:

```
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
```

restart containerd service:
```
systemctl restart containerd
```

containerd from package manager contains runc, but does not contain CNI plugins, to install:  
```
curl -OL https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz

mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz
rm -fr cni-plugins-linux-amd64-v1.4.0.tgz
```

## Install kubernetes binaries

Kubernetes packages repository

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl

```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

install `kubelet`, `kubeadm` and `kubectl`:
```
apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

## Create control plane

pull kube images:
```
kubeadm config images pull
```

create control plane:

```
kubeadm init --skip-phases=addon/kube-proxy
```

## Create worker node

- execute all prior steps
- instead running `kubeadm init`, run `kubeadm join ...` given by control plane setup

## Cilium setup

install helm:
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh
```

download cilium binary:
```
curl -LO https://github.com/cilium/cilium/archive/main.tar.gz
tar xzf main.tar.gz
cd cilium-main/install/kubernetes
```

Install cilium with metrics

https://docs.cilium.io/en/latest/installation/k8s-install-kubeadm/

https://docs.cilium.io/en/latest/observability/grafana/

```
API_SERVER_IP=<your_api_server_ip>
API_SERVER_PORT=<your_api_server_port> (default 6443)

helm install cilium ./cilium \
   --namespace kube-system \
   --set kubeProxyReplacement=true \
   --set k8sServiceHost=${API_SERVER_IP} \
   --set k8sServicePort=${API_SERVER_PORT} \
   --set prometheus.enabled=true \
   --set operator.prometheus.enabled=true \
   --set hubble.enabled=true \
   --set hubble.metrics.enableOpenMetrics=true \
   --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}"
```

# References

## Kubernetes

[Overview](https://kubernetes.io/docs/concepts/overview/)

[Components](https://kubernetes.io/docs/concepts/overview/components/)

[API Server](https://kubernetes.io/docs/concepts/overview/kubernetes-api/)

[Cluster Architecture](https://kubernetes.io/docs/concepts/architecture/) 

[Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

[iptables overview](https://www.redhat.com/sysadmin/iptables)

[Container runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

[containerd getting started](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)


### Videos

[Kubernetes networking: container](https://www.youtube.com/watch?v=B6FsWNUnRo0)

[Kubernetes networking: pod network, cni and plugins](https://www.youtube.com/watch?v=U35C0EPSwoY)

[Kubernetes networking: services](https://www.youtube.com/watch?v=BZk2HUKsxAQ)

[kube-proxy modes: iptables and ipvs](https://www.youtube.com/watch?v=lkXLsD6-4jA)

## eBPF

[What is eBPF?](https://ebpf.io/what-is-ebpf/)

[Kernel.org BPF Documentation](https://www.kernel.org/doc/html/latest/bpf/index.html)

[Overview of eBPF and Cilium](https://www.youtube.com/watch?v=aLq3O3l2LF4)

[Cilium BPF and XDP Reference Guide](https://docs.cilium.io/en/stable/bpf/)

[Cilium Quick Installation](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)

[Systems Performance (book)](https://www.brendangregg.com/systems-performance-2nd-edition-book.html)

[BPF Performance Tools (book)](https://www.brendangregg.com/bpf-performance-tools-book.html)
