variable "cluster_name" {
  default = "example"
}

variable "number_of_bastions" {
  default = 1
}

variable "number_of_k8s_masters" {
  default = 0
}

variable "number_of_k8s_masters_no_etcd" {
  default = 0
}

variable "number_of_etcd" {
  default = 0
}

variable "number_of_k8s_masters_no_floating_ip" {
  default = 1
}

variable "number_of_k8s_masters_no_floating_ip_no_etcd" {
  default = 0
}

variable "number_of_k8s_nodes" {
  default = 0
}

variable "number_of_k8s_nodes_no_floating_ip" {
  default = 1
}

variable "number_of_gfs_nodes_no_floating_ip" {
  default = 0
}

variable "gfs_volume_size_in_gb" {
  default = 75
}

variable "public_key_path" {
  description = "The path of the ssh pub key"
  default = "~/.ssh/id_rsa.pub"
}

variable "image" {
  description = "the image to use"
  default = "Community_Ubuntu_16.04_TSI_20171208_0"
}

variable "image_gfs" {
  description = "Glance image to use for GlusterFS"
  default = "Community_Ubuntu_16.04_TSI_20171208_0"
}

variable "ssh_user" {
  description = "used to fill out tags for ansible inventory"
  default = "ubuntu"
}

variable "ssh_user_gfs" {
  description = "used to fill out tags for ansible inventory"
  default = "ubuntu"
}

variable "flavor_bastion" {
  description = "Use 'nova flavor-list' command to see what your OpenStack instance uses for IDs"
  default = "h1.large.8"
}

variable "flavor_k8s_master" {
  description = "Use 'nova flavor-list' command to see what your OpenStack instance uses for IDs"
  default = "h1.large.8"
}

variable "flavor_k8s_node" {
  description = "Use 'nova flavor-list' command to see what your OpenStack instance uses for IDs"
  default = "h1.large.8"
}

variable "flavor_etcd" {
  description = "Use 'nova flavor-list' command to see what your OpenStack instance uses for IDs"
  default = "h1.large.8"
}

variable "flavor_gfs_node" {
  description = "Use 'nova flavor-list' command to see what your OpenStack instance uses for IDs"
  default = "h1.large.8"
}

variable "network_name" {
  description = "name of the internal network to use"
  default = "internal"
}

variable "dns_nameservers"{
  description = "An array of DNS name server names used by hosts in this subnet."
  type = "list"
  default = []
}

variable "floatingip_pool" {
  description = "name of the floating ip pool to use"
  default = "admin_external_net"
}

variable "external_net" {
  description = "uuid of the external/public network"
  default = "0a2228f2-7f8a-45f1-8e09-9039e1d09975"
}

variable "username" {
  description = "Your openstack username"
}

variable "password" {
  description = "Your openstack password"
}

variable "tenant" {
  description = "Your openstack tenant/project"
}

variable "auth_url" {
  description = "Your openstack auth URL"
}
