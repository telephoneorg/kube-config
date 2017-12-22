#!/usr/bin/env bash
#
# upgrade-k8s:
#
# usage:
#   $  upgrade-k8s.sh 1.7.8 1.7.10 2
#

set -e

OLD_K8S_VERSION=${1:=1.7.8}
NEW_K8S_VERSION=${2:=1.7.10}
KUBELET_RELEASE=${3:=2}

NEW_KUBELET_TAG=v${NEW_K8S_VERSION}_coreos.$KUBELET_RELEASE
THIS_DOMAIN=$(dnsdomainname)
THIS_FQDN=$(hostname -f)


echo -e "
*******

Upgrading k8s:
  hyperkube:  v$OLD_K8S_VERSION  >  v$NEW_K8S_VERSION
  kubelet:    coreos.$KUBELET_RELEASE

  node:       $THIS_FQDN

*******

"

echo "Draining node: $THIS_FQDN ..."
kubectl drain $THIS_FQDN --delete-local-data --ignore-daemonsets --force
sleep 20


echo "Disabling and stopping kubelet ..."
systemctl is-active kubelet && systemctl stop kubelet
systemctl is-enabled kubelet && systemctl disable kubelet
sleep 10


echo "Clearing old kubelet rkt container ..."
rkt gc --grace-period=0
sleep 15


echo "Upgrading kubectl ..."
curl -sSLO https://storage.googleapis.com/kubernetes-release/release/v${NEW_K8S_VERSION}/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin


echo "Upgrading kubelet wrapper ..."
curl -sSLO https://raw.githubusercontent.com/coreos/coreos-overlay/master/app-admin/kubelet-wrapper/files/kubelet-wrapper
chmod +x kubelet-wrapper
mv kubelet-wrapper /usr/local/bin


echo  "Bumping kubelet tag: $OLD_KUBELET_IMAGE >> $NEW_KUBELET_IMAGE ..."
sed -i "s/=.*$/=$NEW_KUBELET_IMAGE/" /etc/kubernetes/kubelet.env
cat /etc/kubernetes/kubelet.env | grep '=v'


echo "Bumping manifest tags: $OLD_K8S_VERSION >> $NEW_K8S_VERSION ..."
find /etc/kubernetes/manifests -type f -exec sed -i "s/$OLD_K8S_VERSION/$NEW_K8S_VERSION/" {} \;
find /etc/kubernetes/manifests -type f -exec grep hyperkube {} \;


systemctl daemon-reload
sleep 5


echo "Re-enabling kubelet ..."
systemctl enable kubelet
systemctl start kubelet


echo -e "
*******
DONE!"
*******
"
