echo "[containerd] apt installing..."
# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
apt install -y containerd

mkdir -p /etc/containerd/
containerd config default > /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

echo "[containerd] restarting..."
systemctl restart containerd

echo "[containerd] installing cni plugins..."
# containerd from package manager contains runc, bot does not contain CNI plugins
curl -OL https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz
rm -fr cni-plugins-linux-amd64-v1.4.0.tgz
