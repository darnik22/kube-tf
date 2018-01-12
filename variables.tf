### OpenStack Credentials
variable "otc_username" {}

variable "otc_password" {}

variable "otc_domain_name" {}

### Project Settings
# The name of the project. It is used to prefix VM names. It should be unique among
# OTC as it is used to create names of VMs. The first provider will have the following
# FQDN: ${project}-op-01.${dnszone} publicly accessible.
variable "project" {
#   default = "od"
}

# # A valid email will be needed when creating cerificates
# variable "email" {
# #  default = ""
# }


### The following variables can optionally be set. Reasonable defaults are provided.

### Ceph cluster settings
# This is the number of contoller nodes. It should be 1.
variable "kube-ctlr_count" {
  default = "1"
}

# The number of workers of Kube cluster. 
variable "kube-work_count" {
  default = "5"
}

### VM (Instance) Settings
# The flavor name used for Ceph monitors and OSDs. 
variable "flavor_name" {
  default = "h1.large.4"
#  default = "hl1.8xlarge.8" # Setting this flavor may require setting vol_type and vol_prefix
}

variable "work_flavor_name" {
  default = "h1.xlarge.4"
#  default = "hl1.8xlarge.8" # Setting this flavor may require setting vol_type and vol_prefix
}



# The image name used for all instances
variable "image_name" {
#  default = "Community_Ubuntu_16.04_TSI_latest"
  default = "Community_Ubuntu_16.04_TSI_20171116_0"
}

# Availability zone 
variable "availability_zone" {
  default = "eu-de-01"
}


### OTC Specific Settings
variable "otc_tenant_name" {
  default = "eu-de"
}

variable "endpoint" {
  default = "https://iam.eu-de.otc.t-systems.com:443/v3"
}

variable "external_network" {
  default = "admin_external_net"
}

#### Internal usage variables ####
# The user name for loging into the VMs.
variable "ssh_user_name" {
  default = "ubuntu"
}


variable "public_key_file" {
  default = "/home/ubuntu/.ssh/id_rsa.pub"
}

variable "sources_list_dest" {
#  default = "/dev/null"
  default = "/etc/apt/sources.list"   # Use this if OTC debmirror has problems
}

