variable "RGName_AKS" {
  default = "AZ-K8S-INFRA"
}
variable "RGLocation" {
  default = "AUSTRALIA SOUTHEAST"
}
resource "azurerm_container_registry" "az_fs_bkp_acr" {
  name                     = "azfsbkpacr"
  location            = "${var.RGLocation}"
  resource_group_name = "${var.RGName_AKS}"
  sku                      = "Standard"
  admin_enabled            = false
  #georeplication_locations = ["East US", "West Europe"]
}