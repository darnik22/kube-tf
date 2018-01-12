resource "openstack_networking_floatingip_v2" "vpn" {
  depends_on = ["openstack_compute_instance_v2.vpn"]
  port_id  = "${openstack_networking_port_v2.vpn-port.id}"
  pool  = "${var.external_network}"
}

resource "openstack_networking_floatingip_v2" "kube-ctlr" {
  depends_on = ["openstack_compute_instance_v2.kube-ctlr"]
  port_id  = "${element(openstack_networking_port_v2.ctlr-port.*.id, count.index)}"
  count = "${var.kube-ctlr_count}"
  pool  = "${var.external_network}"
}

# resource "openstack_networking_floatingip_v2" "kube-work" {
#   depends_on = ["openstack_compute_instance_v2.kube-work"]
#   port_id  = "${element(openstack_networking_port_v2.work-port.*.id, count.index)}"
#   count = "${var.kube-work_count}"
#   pool  = "${var.external_network}"
# }

resource "openstack_compute_instance_v2" "vpn" {
  depends_on = ["openstack_networking_router_interface_v2.interface"]
  name            = "${var.project}-vpn"
  image_name      = "${var.image_name}"	
  flavor_name     = "${var.flavor_name}"
  key_pair        = "${openstack_compute_keypair_v2.otc.name}"
  availability_zone = "${var.availability_zone}"
  network {
    port = "${openstack_networking_port_v2.vpn-port.id}"
    uuid = "${openstack_networking_network_v2.network.id}"
    access_network = true
  }
}

resource "openstack_networking_port_v2" "vpn-port" {
  network_id         = "${openstack_networking_network_v2.network.id}"
  security_group_ids = [
    "${openstack_compute_secgroup_v2.secgrp_vpn.id}",
    "${openstack_compute_secgroup_v2.secgrp_kube.id}",
    "${openstack_compute_secgroup_v2.secgrp_jmp.id}",
  ]
  admin_state_up     = "true"
  fixed_ip           = {
    subnet_id        = "${openstack_networking_subnet_v2.subnet.id}"
  }
  allowed_address_pairs = {
    ip_address = "1.1.1.1/0"
  }
}

resource "openstack_compute_instance_v2" "kube-ctlr" {
  depends_on = ["openstack_networking_router_interface_v2.interface"]
  count           = "${var.kube-ctlr_count}"
  name            = "${var.project}-kube-ctlr"
  image_name      = "${var.image_name}"	
  flavor_name     = "${var.flavor_name}"
  key_pair        = "${openstack_compute_keypair_v2.otc.name}"
  availability_zone = "${var.availability_zone}"
  network {
    port = "${element(openstack_networking_port_v2.ctlr-port.*.id, count.index)}"
    uuid = "${openstack_networking_network_v2.network.id}"
    access_network = true
  }
}

resource "openstack_networking_port_v2" "ctlr-port" {
  count              = "${var.kube-ctlr_count}"
  network_id         = "${openstack_networking_network_v2.network.id}"
  security_group_ids = [
    "${openstack_compute_secgroup_v2.secgrp_jmp.id}",
    "${openstack_compute_secgroup_v2.secgrp_kube.id}",
  ]
  admin_state_up     = "true"
  fixed_ip           = {
    subnet_id        = "${openstack_networking_subnet_v2.subnet.id}"
  }
  allowed_address_pairs = {
    ip_address = "1.1.1.1/0"
  }
}

resource "null_resource" "provision-work" {
  count = "${var.kube-work_count}"
  connection {
    bastion_host = "${openstack_networking_floatingip_v2.vpn.address}"
    host     = "${element(openstack_compute_instance_v2.kube-work.*.access_ip_v4, count.index)}"
    user     = "${var.ssh_user_name}"
    agent = true
  }
  provisioner "file" {
    source = "etc/sources.list"
    destination = "sources.list"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp sources.list ${var.sources_list_dest}", 
      "sudo apt-get -y update",
      "sudo apt-get -y install python",
#      "sudo ip route add 10.8.0.0/24 via ${openstack_compute_instance_v2.vpn.access_ip_v4}",
    ]
  }
}

resource "null_resource" "provision-vpn" {
  depends_on = ["openstack_networking_floatingip_v2.vpn"]
  connection {
    host     = "${openstack_networking_floatingip_v2.vpn.address}"
    user     = "${var.ssh_user_name}"
    agent = true
  }
  provisioner "file" {
    source = "etc/sources.list"
    destination = "sources.list"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp sources.list ${var.sources_list_dest}", 
      "sudo apt-get -y update",
      "sudo apt-get -y install python",
#      "sudo ip route add 10.233.0.0/16 via ${openstack_compute_instance_v2.kube-ctlr.access_ip_v4}",
    ]
  }
  provisioner "local-exec" {
    command = "./setup-vpn.sh ${openstack_networking_floatingip_v2.vpn.address} ${openstack_compute_instance_v2.kube-ctlr.access_ip_v4}"
  }
  provisioner "local-exec" {
    command = "echo -n ${join(" ", openstack_compute_instance_v2.kube-work.*.access_ip_v4)} ${join(" ", openstack_compute_instance_v2.kube-ctlr.*.access_ip_v4)}  ${openstack_compute_instance_v2.vpn.access_ip_v4} > instance-ips.out"
  }
  provisioner "local-exec" {
    command = "./check-ips.sh"
  }
# The following is not working as expected - terraform issue #14403
  # provisioner "local-exec" {
  #   when = "destroy"
  #   on_failure = "continue"
  #   command = "echo Bringing down client vpn ... && ./down-vpn.sh"
  # }
}

resource "null_resource" "provision-kubespray" {
  depends_on = ["openstack_compute_instance_v2.kube-work", "openstack_compute_instance_v2.kube-ctlr", "null_resource.provision-vpn", "null_resource.provision-ctlr"]
  provisioner "local-exec" {
    command = "echo \"${join("\n", formatlist("%s ansible_host=%s", openstack_compute_instance_v2.kube-ctlr.*.name, openstack_compute_instance_v2.kube-ctlr.*.access_ip_v4))}\n${join("\n", formatlist("%s ansible_host=%s", openstack_compute_instance_v2.kube-work.*.name, openstack_compute_instance_v2.kube-work.*.access_ip_v4))}\n\n[kube-master]\n${join("\n", openstack_compute_instance_v2.kube-ctlr.*.name)}\n\n[etcd]\n${join("\n", openstack_compute_instance_v2.kube-ctlr.*.name)}\n\n[kube-node]\n${join("\n", openstack_compute_instance_v2.kube-work.*.name)}\n\n[k8s-cluster:children]\nkube-node\nkube-master\n\" > inventory.ini"
  }
  
  provisioner "local-exec" {
    command = "ansible-playbook -b -i inventory.ini playbooks/kubespray/cluster.yml -e dashboard_enabled=true -e kubeconfig_localhost=true -e kube_network_plugin=flannel"
  }
}

resource "null_resource" "provision-admin" {
  depends_on = ["null_resource.provision-kubespray"]
  connection {
      host     = "${openstack_networking_floatingip_v2.kube-ctlr.address}"
      user     = "${var.ssh_user_name}"
      agent = true
  }
  provisioner "file" {
    source = "playbooks/kubespray/artifacts/admin.conf"
    destination = "admin.conf"
  }
}

resource "null_resource" "provision-ctlr" {
  depends_on = ["openstack_networking_floatingip_v2.kube-ctlr","null_resource.provision-work"]
  provisioner "local-exec" {
    command = "./local-setup.sh ${var.project} ${var.kube-ctlr_count} ${var.kube-work_count} 0 0"
  }
  # provisioner "local-exec" {
  #   command = "echo ${openstack_networking_floatingip_v2.ceph-mgt.address} > MGT_IP"
  # }
  # triggers {
  #   cluster_instance_ids = "${join(",", openstack_networking_floatingip_v2.ceph-mgt.*.address)}"
  # }
  connection {
      host     = "${openstack_networking_floatingip_v2.kube-ctlr.address}"
      user     = "${var.ssh_user_name}"
      agent = true
  }
  provisioner "file" {
    source = "etc.tgz"
    destination = "etc.tgz"
  }
  provisioner "remote-exec" {
    inline = [
      "tar zxvf etc.tgz",
      "sudo cp etc/sources.list ${var.sources_list_dest}", # if debmirror at OTC is not working
      "sudo apt-get -y update",
      "sudo apt-get -y install python",
#      "sudo ip route add 10.8.0.0/24 via ${openstack_compute_instance_v2.vpn.access_ip_v4}",
      "sudo cp etc/ssh_config /etc/ssh/ssh_config",
    ]
  }
}

resource "openstack_compute_instance_v2" "kube-work" {
  depends_on = ["openstack_networking_router_interface_v2.interface"]
  count           = "${var.kube-work_count}"
  name            = "${var.project}-kube-work-${format("%02d", count.index+1)}"
  image_name      = "${var.image_name}"	
  flavor_name     = "${var.work_flavor_name}"
  key_pair        = "${openstack_compute_keypair_v2.otc.name}"
  availability_zone = "${var.availability_zone}"

  network {
    port = "${element(openstack_networking_port_v2.work-port.*.id, count.index)}"
    uuid = "${openstack_networking_network_v2.network.id}"
    access_network = true
  }
}

resource "openstack_networking_port_v2" "work-port" {
  count              = "${var.kube-work_count}"
  network_id         = "${openstack_networking_network_v2.network.id}"
  security_group_ids = [
    "${openstack_compute_secgroup_v2.secgrp_kube.id}",
  ]
  admin_state_up     = "true"
  fixed_ip           = {
    subnet_id        = "${openstack_networking_subnet_v2.subnet.id}"
  }
  allowed_address_pairs = {
    ip_address = "1.1.1.1/0"
  }
}


resource "openstack_compute_keypair_v2" "otc" {
#  depends_on = ["null_resource.local-setup"]
  name       = "${var.project}-otc"
  public_key = "${file("${var.public_key_file}")}"
}

resource "openstack_networking_network_v2" "network" {
  name           = "${var.project}-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${var.project}-subnet"
  network_id      = "${openstack_networking_network_v2.network.id}"
  cidr            = "192.168.5.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "100.125.4.25"]
}

provider "openstack" {
  user_name   = "${var.otc_username}"
  password    = "${var.otc_password}"
  tenant_name = "${var.otc_tenant_name}"
  domain_name = "${var.otc_domain_name}"
  auth_url    = "${var.endpoint}"
}
resource "openstack_networking_router_route_v2" "vpn_route" {
  depends_on       = ["openstack_networking_router_interface_v2.interface"]
  router_id        = "${openstack_networking_router_v2.router.id}"
  destination_cidr = "10.8.0.0/24"
  next_hop         = "${openstack_compute_instance_v2.vpn.access_ip_v4}"
}
# resource "openstack_networking_router_route_v2" "kube_route" {
#   depends_on       = [
#     "openstack_networking_router_interface_v2.interface",
#     "null_resource.provision-kubespray"
#   ]
#   router_id        = "${openstack_networking_router_v2.router.id}"
#   destination_cidr = "10.233.0.0/16"
#   next_hop         = "${openstack_compute_instance_v2.kube-ctlr.access_ip_v4}"
# }

resource "openstack_networking_router_v2" "router" {
  name             = "${var.project}-router"
  admin_state_up   = "true"
  #external_gateway = "${data.openstack_networking_network_v2.external_network.id}"
  external_gateway = "0a2228f2-7f8a-45f1-8e09-9039e1d09975"
  enable_snat = true
}

resource "openstack_networking_router_interface_v2" "interface" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet.id}"
}

resource "openstack_compute_secgroup_v2" "secgrp_jmp" {
  name        = "${var.project}-secgrp-jmp"
  description = "Jumpserver Security Group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 6443
    to_port     = 6443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 8443
    to_port     = 8443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "secgrp_kube" {
  name        = "${var.project}-secgrp-kube"
  description = "Kube stack Security Group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 3000
    to_port     = 3000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 8082
    to_port     = 8082
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    self        = true
  }
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    self        = true
  }
}

resource "openstack_compute_secgroup_v2" "secgrp_vpn" {
  name        = "${var.project}-secgrp-vpn"
  description = "VPN stack Security Group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 1194
    to_port     = 1194
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 1194
    to_port     = 1194
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    self        = true
  }
}

