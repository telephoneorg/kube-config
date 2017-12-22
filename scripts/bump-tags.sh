#!/usr/bin/env bash

set -e

OLD_K8S_VERSION=${1:=1.8.5}
NEW_K8S_VERSION=${2:=1.8.5}
NEW_KUBELET_IMAGE=${3:v${NEW_K8S_VERSION}_coreos.0}


echo  "Bumping kubelet image to: $NEW_KUBELET_IMAGE ..."
sed -i "s/=.*$/=$NEW_KUBELET_IMAGE/" kubelet.env
cat kubelet.env | grep '=v'


echo "Bumping manifest tags: $OLD_K8S_VERSION >> $NEW_K8S_VERSION ..."
find manifests -type f -exec sed -i "s/$OLD_K8S_VERSION/$NEW_K8S_VERSION/" {} \;
find manifests -type f -exec grep hyperkube {} \;
