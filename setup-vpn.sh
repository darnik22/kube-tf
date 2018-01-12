#!/bin/bash
# if an old openvpn-kube client process is still running kill it before running the playbook
ps -ef | grep openvpn-kube | sudo kill `awk '{print $2}'`
ssh-keygen -R $1
ssh -o StrictHostKeyChecking=no $1 hostname
printf "[vpn]\n$1" > inventory
ansible-playbook -i inventory playbooks/openvpn/site.yml -e kube_ctlr_ip=$2
