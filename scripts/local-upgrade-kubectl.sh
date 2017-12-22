#!/usr/bin/env bash
#
# upgrade-k8s:
#
# usage:
#   $  upgrade-k8s.sh 1.8.5
#

set -e

K8S_VERSION=${1:=1.8.5}

echo "Upgrading kubectl ..."
curl -sSLO "https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/darwin/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl-$K8S_VERSION
ln -sf /usr/local/bin/kubectl-$K8S_VERSION /usr/local/bin/kubectl
