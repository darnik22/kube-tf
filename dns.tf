resource "openstack_dns_zone_v2" "dnszone" {
  name  = "${var.dnszone}."
  email = "${var.email}"
}

resource "openstack_dns_recordset_v2" "kube-zone" {
  zone_id = "${openstack_dns_zone_v2.dnszone.id}"
  name    = "kube.${var.dnszone}."
  type    = "NS"
  records = ["nskube.${var.dnszone}."] 
}

resource "openstack_dns_recordset_v2" "ns-kube-ip" {
  zone_id = "${openstack_dns_zone_v2.dnszone.id}"
  name    = "nskube.${var.dnszone}."
  type    = "A"
#  records = ["10.10.10.10"]
  records = ["${openstack_networking_floatingip_v2.kube-ctlr.address}"]
}

resource "null_resource" "kube-dns" {
  depends_on = ["null_resource.provision-kubespray"]
  connection {
    host     = "${openstack_networking_floatingip_v2.kube-ctlr.address}"
    user     = "${var.ssh_user_name}"
    agent = true
  }
  provisioner "remote-exec" {
    inline = [
      "until kubectl get svc kube-dns -n kube-system; do echo Waiting for kube-dns svc; sleep 1; done",
      "kubectl patch svc kube-dns -n kube-system -p '{\"spec\": { \"externalIPs\": [ \"${openstack_compute_instance_v2.kube-ctlr.access_ip_v4}\"]}}'", 
    ]
  }
}
