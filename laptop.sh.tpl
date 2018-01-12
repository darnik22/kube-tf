#!/bin/bash
OVPN_DIR=~/ovpn
mkdir $OVPN_DIR
cd $OVPN_DIR
scp {{inventory_hostname}}:{{ca_dir}}/keys/laptop.'*' .
scp {{inventory_hostname}}:{{ca_dir}}/keys/ca.crt .
scp {{inventory_hostname}}:client-conf/laptop.conf .
openvpn --config client.conf --daemon
#scp {{kube-ctlr-ip}}:admin.conf .
#kubectl --kubeconfig admin.conf proxy
