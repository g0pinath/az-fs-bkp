terraform {
  backend "azurerm" {

    subscription_id      = "6338b6ed-d23f-403f-91a8-aea57900b1a6"
    tenant_id            = "9deab971-f9a9-4f67-b314-d00630c8e2d4"
    resource_group_name  = "AZ-K8S-FSBKP"
    storage_account_name = "azfsbkptf"
    container_name       = "nonprd-tfstates"
    key                  = "nonprod.tfstate"
    
  }
}