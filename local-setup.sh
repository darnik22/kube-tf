#!/bin/bash

project=$1
mon_count=$2
osd_count=$3
client_count=$4
provider_count=$5
echo "[mgt] 
${project}-ceph-mgt
 
[mons]" > etc/ansible-hosts
for ((i=1; i<=$mon_count; i++)) do
    printf "${project}-ceph-mon-%02d\n" $i >> etc/ansible-hosts
done

# ${project}-ceph-mgt01 

echo "
[osds]" >> etc/ansible-hosts
for ((i=1; i<=$osd_count; i++)) do
    printf "${project}-ceph-osd-%02d\n" $i >> etc/ansible-hosts
done

echo "
[clients]" >> etc/ansible-hosts
for ((i=1; i<=$client_count; i++)) do
    printf "${project}-client-%02d\n" $i >> etc/ansible-hosts
done

echo "
[ops]" >> etc/ansible-hosts
for ((i=1; i<=$provider_count; i++)) do
    printf "${project}-op-%02d\n" $i >> etc/ansible-hosts
done

sed -e "s/PROJECT/${project}/g" etc/ssh_config.tpl > etc/ssh_config

tar zchvf playbooks.tgz playbooks
tar zcvf etc.tgz etc
