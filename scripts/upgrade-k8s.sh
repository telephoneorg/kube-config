#!/usr/bin/env bash
#
# upgrade-k8s:
#
# usage:
#   $  upgrade-k8s.sh 1.8.5
#

set -e

K8S_VERSION=${1:=1.8.5}


echo -e "
*******

Upgrading k8s to: $K8S_VERSION

*******

"

echo "Draining node: $(hostname -f)..."
kubectl drain $(hostname -f) --delete-local-data --ignore-daemonsets --force
sleep 5


echo "Disabling and stopping kubelet ..."
systemctl is-active kubelet && systemctl stop kubelet
systemctl is-enabled kubelet && systemctl disable kubelet
sleep 1


echo "Clearing old kubelet rkt container ..."
rkt gc --grace-period=0
sleep 5


echo "Upgrading kubectl ..."
curl -sSLO "https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin


echo "Upgrading kubelet wrapper ..."
curl -sSLO https://raw.githubusercontent.com/coreos/coreos-overlay/master/app-admin/kubelet-wrapper/files/kubelet-wrapper
chmod +x kubelet-wrapper
mv kubelet-wrapper /usr/local/bin


echo "Checking out kube-config v${K8S_VERSION} ..."
cd /etc/kubernetes

# git fetch
# git checkout v${K8S_VERSION}
git pull origin master
systemctl daemon-reload
sleep 1


echo "Re-enabling kubelet ..."
systemctl enable kubelet
systemctl start kubelet

kubectl uncordon $(hostname -f)

echo -e "
*******
DONE!
*******
"
