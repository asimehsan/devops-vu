#!/usr/bin/bash
/usr/bin/echo "enable system for kubenetes"
/usr/bin/echo "overlay" > /etc/modules-load.d/containerd.conf
/usr/bin/echo "br_netfilter" >> /etc/modules-load.d/containerd.conf
/usr/sbin/modprobe overlay
/usr/sbin/modprobe br_netfilter
/usr/bin/echo "net.bridge.bridge-nf-call-ip6tables = 1" > /etc/sysctl.d/kubernetes.conf
/usr/bin/echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
/usr/bin/echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
/usr/sbin/sysctl -p
/usr/sbin/sysctl --system
/usr/bin/curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
/usr/bin/add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
/usr/bin/apt update 
/usr/bin/dpkg --configure -a
/usr/bin/apt install -y containerd.io
/usr/bin/rm -f /etc/containerd/config.toml
systemctl daemon-reload
systemctl start containerd
systemctl enable containerd
apt-get update && apt-get install -y apt-transport-https ca-certificates curl
mkdir /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
/usr/bin/grep -v "swap" /etc/fstab > /tmp/fstab && mv /tmp/fstab /etc/fstab
/usr/sbin/swapoff -a
/usr/bin/apt-get update 
/usr/bin/apt-get install kubelet kubeadm kubectl kubernetes-cni -y
/usr/bin/apt-mark hold kubelet kubeadm kubectl
/usr/bin/systemctl restart containerd.service
/usr/bin/echo "now run kubeadm init on master to setup the controll-plane"

