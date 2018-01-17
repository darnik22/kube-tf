# Terraform/ansible files for creating a k8s cluster on OTC and deploying the onedata singlenode landscape

## Configuring
In order to build your cluster you need to:
* run ssh-agent and add your key. It will further be used to login into the created VMs.
* provide your openstack credentials by editting parameter.tvars. The username should be the same as shown in the OTC console. You can not use the email or mobile number, which can also be used to login to the OTC web console. 
* eventually change values in varaibles.tf according to the comments in this file.

In order to integrate kube-dns with your domain you need to:
* have a registered Internet domain which uses (delegates to) the following nameservers:
  * ns1.open-telekom-cloud.com.
  * ns2.open-telekom-cloud.com.

Edit variables.tf and set at least the following vars:
* dnszone - your registered Internet domain. The publicly resolvable cluster domain will be kube.${dnszone}.
* email - your email
* project - project name. It is used to prefix VM names. It should be unique among OTC as it is used to create names of VMs.

The variables can also be provided interactively or set as command line args. For example:
```
terraform apply -var project=example_project -var email=joe@example.com ....
```

## Running
Build your cluster issuing:
```
terraform init
terraform apply -var-file parameter.tvars
```

## Accessing your cluster
After a successful built the public and private IP of the k8s cluster master node are displayed. In order to have access to the private addresses you need to connect to the VPN server, which has been prepared. If the terraform has been run from a linux machine then on that machine a VPN client has been run already by the scripts. You can also use the "scp ubuntu@..." commands displayed after successful terraform execution to manually start a VPN connection and kube proxy on another machine, e.g., your laptop or desktop. An example commands looks like:
```
scp ubuntu@80.158.20.236:laptop.sh .; ./laptop.sh
```
You can then access the dashboard from your laptop at localhost:8001/ui. Use the default token to authenticate. Get it with a command similar to:
```
kubectl describe secret default-token-8zr4r
```

## Configure the landscape

Edit the file k8s-deployment/landscapes/singlenode/landscape.yaml and change  tld to your domain.

## Example command flow 
```
eval `ssh-agent`
ssh-key
git clone https://github.com/darnik22/kube-tf.git
cd kube-tf
vi parameter.tvars
vi variables.tf
vi k8s-deployment/landscapes/singlenode/landscape.yaml
terraform init
terraform apply -var-file parameter.tvars
ssh -A ubuntu@THE_IP_OF_CTLR_NODE
kubectl cluster-info
kubectl get pod

```

