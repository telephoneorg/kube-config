#!/usr/bin/env bash

set -e

THIS_FQDN=$(hostname -f)


echo "Draining node: $THIS_FQDN ..."
kubectl drain $THIS_FQDN --delete-local-data --ignore-daemonsets --force && sleep 15 || true


echo "Disabling and stopping kubelet ..."
systemctl is-active kubelet && systemctl stop kubelet
systemctl is-enabled kubelet && systemctl disable kubelet
sleep 5


echo "Stopping docker ..."
[[ $(docker ps -q | wc -l) -gt 0 ]] && docker rm -f $(docker ps -q)
[[ $(docker ps -aq | wc -l) -gt 0 ]] && docker rm  $(docker ps -aq)
[[ $(docker volume ls -q | wc -l) -gt 0 ]] && docker volume rm $(docker volume ls -q)
systemctl is-active docker && systemctl stop docker
sleep 5


echo "Clearing old kubelet rkt containers ..."
rkt gc --grace-period=0
sleep 10


echo "Clearing mounts ..."
mount | grep -q kubelet && umount $(mount | grep kubelet | awk '{print $3}')
sleep 5


echo "Clearing host volume state ..."
[[ -d /var/lib/kubelet ]] && rm -rf /var/lib/kubelet/*
[[ -d /var/lib/ceph ]] && rm -rf /var/lib/ceph/*
[[ -d /var/lib/rook ]] && rm -rf /var/lib/rook/*
[[ -d /var/lib/etcd ]] && rm -rf /var/lib/etcd/*


echo "Clearing iptables ..."
iptables -F
iptables -t nat -F


echo "Re-enabling kubelet ..."
systemctl enable kubelet
systemctl start kubelet

echo -e "

*******
DONE!
*******

"
