output "vpn server public address" {
  value = "${openstack_networking_floatingip_v2.vpn.address}"
}

output "Controller node public address" {
  value = "${openstack_networking_floatingip_v2.kube-ctlr.address}"
}

output "kube-ctlr address" {
  value = "${openstack_compute_instance_v2.kube-ctlr.*.access_ip_v4}"
}

output "kube-work address" {
  value = "${openstack_compute_instance_v2.kube-work.*.access_ip_v4}"
}

output "laptop.sh" {
  value = "scp ubuntu@${openstack_networking_floatingip_v2.vpn.address}:laptop.sh .; ./laptop.sh"
}

