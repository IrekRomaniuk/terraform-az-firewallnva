// vnet creation 
module "hubnetwork" {
    source              = "./modules/networkbuild"
    vnet_name           = var.hub_vnet_name
    resource_group_name = "${var.prefix}-${var.hub_vnet_name}"
    location            = "eastus"
    address_space       = "10.110.0.0/16"
    subnet_prefixes     = ["10.110.1.0/26", "10.110.2.0/24", "10.110.3.0/24", "10.110.4.0/24"]
    subnet_names        = ["AzureFirewallSubnet", "ManagementSubnet", "SharedServices","AzureBastionSubnet"]
}

module "spoke1network" {
    source              = "./modules/networkbuild"
    vnet_name           = var.spoke1_vnet_name
    resource_group_name = "${var.prefix}-${var.spoke1_vnet_name}"
    location            = "eastus"
    address_space       = "10.111.0.0/16"
    subnet_prefixes     = ["10.111.1.0/24", "10.111.2.0/24", "10.111.3.0/24", "10.111.4.0/24"]
    subnet_names        = ["WebTier", "LogicTier", "DatabaseTier","AzureBastionSubnet"]
}
module "spoke2network" {
    source              = "./modules/networkbuild"
    vnet_name           = var.spoke2_vnet_name
    resource_group_name = "${var.prefix}-${var.spoke2_vnet_name}"
    location            = "eastus"
    address_space       = "10.112.0.0/16"
    subnet_prefixes     = ["10.112.1.0/24", "10.112.2.0/24", "10.112.3.0/24", "10.112.4.0/24"]
    subnet_names        = ["WebTier", "LogicTier", "DatabaseTier","AzureBastionSubnet"]
}

// nsg associations 

resource "azurerm_subnet_network_security_group_association" "hub_management_nsg_association" {
  subnet_id                 = module.hubnetwork.vnet_subnets[1]
  network_security_group_id = azurerm_network_security_group.hub_mgmt_nsg.id
  depends_on = [azurerm_firewall.hub]
  // This depends on will prevent a deadlock between nsg and nic\firewall - as per open issue 
  // https://github.com/terraform-providers/terraform-provider-azurerm/issues/2489
}

resource "azurerm_subnet_network_security_group_association" "spoke_web_nsg_association" {
  subnet_id                 = module.spoke1network.vnet_subnets[0]
  network_security_group_id = azurerm_network_security_group.spoke_web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "spoke2_web_nsg_association" {
  subnet_id                 = module.spoke2network.vnet_subnets[0]
  network_security_group_id = azurerm_network_security_group.spoke_web_nsg.id
}

// route table associations

resource "azurerm_subnet_route_table_association" "spoke1_udr_assoc" {
  subnet_id      = module.spoke1network.vnet_subnets[0]
  route_table_id = azurerm_route_table.spoke_rt_table.id
}

resource "azurerm_subnet_route_table_association" "spoke2_udr_assoc" {
  subnet_id      = module.spoke2network.vnet_subnets[0]
  route_table_id = azurerm_route_table.spoke_rt_table.id
}

// peerings

resource "azurerm_virtual_network_peering" "hubspoke1" {
  name                      = "hubspoke1"
  resource_group_name       = "${var.prefix}-${module.hubnetwork.vnet_name}"
  virtual_network_name      = module.hubnetwork.vnet_name
  remote_virtual_network_id = module.spoke1network.vnet_id
}

resource "azurerm_virtual_network_peering" "spoke1hub" {
  name                      = "spoke1hub"
  resource_group_name       = "${var.prefix}-${module.spoke1network.vnet_name}"
  virtual_network_name      = module.spoke1network.vnet_name
  remote_virtual_network_id = module.hubnetwork.vnet_id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "hubspoke2" {
  name                      = "hubspoke2"
  resource_group_name       = "${var.prefix}-${module.hubnetwork.vnet_name}"
  virtual_network_name      = module.hubnetwork.vnet_name
  remote_virtual_network_id = module.spoke2network.vnet_id
}

resource "azurerm_virtual_network_peering" "spoke2hub" {
  name                      = "spoke2hub"
  resource_group_name       = "${var.prefix}-${module.spoke2network.vnet_name}"
  virtual_network_name      = module.spoke2network.vnet_name
  remote_virtual_network_id = module.hubnetwork.vnet_id
  allow_forwarded_traffic   = true
}