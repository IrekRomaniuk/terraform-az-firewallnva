# Azure Firewall with Hub and Spoke model Simple Deployment

![Alt text](../master/supporting/diagram.jpg?raw=true "Diagram")

This code will quickly (usually within 15 mins) build a simple deployment of a hub and spoke architecture. In each spoke is n-tier subnets and a single Linux server which is configured with a simple web page showing the hostname and uptime. This helps if you wish to test load balancing, or just if you wish to test HTTP connections to the VMs.

The resources are provisioned into a number of resource groups by resource type, for instance, compute, network etc.

This is designed for lab use, and further security hardening would be recommended if you wish to use this for any production workloads. This lab will provide you with the basic foundation in order to test and learn more about Azure Firewall.

# Updated from from sdcscripts/terraform-az-firewallnva fork

- resource prefix added
- defaults updated
- bastion subnets added

## To be created/edited

Add main.tf with tenant, subscription id as well as client id and secret

```
terraform {
required_version = "~> 0.12.0"
}

provider "azurerm" {
  features {}
  version = "~> 2.0.0"
  tenant_id="
  subscription_id=""
  client_id=""
  client_secret=""
  skip_provider_registration = true
  
}
```


Will be asked for vm password and resource group prefix. 

Also edit below:

- network.tf: respurce groups location and subnet prefixes
- copy terraform.tfvars.example as terraform.tfvars and editvariables if necessary

## Result

Should get the below output at the end (Private ip might be different, depends on network.tf edited):

```
...
Apply complete! Resources: 58 added, 0 changed, 0 destroyed.

Outputs:

firewall_public_dns_fqdn = xxx.eastus.cloudapp.azure.com
hub_vm_dns_label = xxx.eastus.cloudapp.azure.com
spoke1_vm_private_ip = 10.111.1.4
spoke2_vm_private_ip = 10.112.1.4
vm_password = xxx
vm_username = xxx
```

![Alt text](../master/supporting/netlab.jpg?raw=true "Resource groups created with prefix 'netlab'")

then

```
$ ssh azureuser@xxx.eastus.cloudapp.azure.com
[azureuser@azurefw-hub-vm ~]$ ssh 10.111.1.4
[azureuser@spoke1-web-vm ~]$
```

Password:

## ToDo

- add bastion hosts in hub and spoke subnets
- password fromm key vault instead of prompted

## Remarks

Do not pass input variables when destroying

## Requirements

* terraform core `0.12.n`
* tested with terraform AzureRM provider `2.0.0`
* an `az cli` authenticated connection to an azure subscription (or use a managed identity or service principal to the azurerm provider block using instructions found here- <https://www.terraform.io/docs/providers/azurerm>)

> Deploying this module will incur cost in your subscription!

The key points and features are:

* **Easy Run**: There is a `terraform.tfvars.example` file which you should rename to `terraform.tfvars` and you will then need to set the password for the vmadmin account. All other variable entries can be used or you can optionally set them to new values if you wish. Afterwards, simply run Terraform init, Terraform apply and it will deploy all resources into East US.  

* **Network Security Group Rules**: This deployment will automatically attach an NSG rule to the web subnets in each spoke network to allow SSH from the hub management subnet for both SSH and ICMP. Another NSG will allow SSH direct to the management VM, be aware of this, you may wish to disallow this and set up alternative methods to remote to the VM such as Azure Bastion, VPN or Expressroute.

* **Azure Firewall Configuration**: The firewall is configured with a Network Rule Collection which will allow spoke to spoke SSH connections. Port 80 is also permitted from the hub management VM to each spoke VM, which you can test using facilities such as curl. i.e curl 10.100.1.4 (if the IP for the spoke VM is 10.100.1.4).

* **Terraform Outputs**: The configuration will output the Azure firewall public FQDN, the hub management VM public FQDN, the private IP addresses of both the web VMs in each vnet spoke and also the username and password for all VMs.

## Terraform Getting Started & Documentation

If you're new to Terraform and want to get started creating infrastructure, please checkout our [Getting Started](https://www.terraform.io/intro/getting-started/install.html) guide, available on the [Terraform website](http://www.terraform.io).

All documentation is available on the [Terraform website](http://www.terraform.io):

* [Intro](https://www.terraform.io/intro/index.html)
* [Docs](https://www.terraform.io/docs/index.html)
