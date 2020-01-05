terraform {
  backend "azurerm" {

    subscription_id      = ""
    tenant_id            = ""
    resource_group_name  = "AZ-K8S-FSBKP"
    storage_account_name = ""
    container_name       = "nonprd-tfstates"
    key                  = "nonprod.tfstate"
    
  }
}
