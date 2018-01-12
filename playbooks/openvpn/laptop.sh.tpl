#!/bin/bash
OVPN_DIR=~/ovpn
mkdir $OVPN_DIR
cd $OVPN_DIR
ssh-keygen -R {{inventory_hostname}}
scp ubuntu@{{inventory_hostname}}:{{ca_dir}}/keys/laptop.'*' .
scp ubuntu@{{inventory_hostname}}:{{ca_dir}}/keys/ca.crt .
scp ubuntu@{{inventory_hostname}}:laptop.conf .
openvpn --config laptop.conf > laptop.log 2>&1 &
sleep 15
ssh-keygen -R {{kube_ctlr_ip}}
scp ubuntu@{{kube_ctlr_ip}}:admin.conf .
kubectl --kubeconfig admin.conf proxy
