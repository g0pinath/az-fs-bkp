resource "azurerm_resource_group" "AZK8SINFRA" {
  name     = "${var.RGName_AKS}"
  location = "${var.RGLocation}"
}

resource "azurerm_kubernetes_cluster" "AZK8SDEV" {
  name                = "${var.AKSClusterName}"
  location            = "${var.RGLocation}"
  resource_group_name = "${var.RGName_AKS}"
  dns_prefix          = "${var.AKSDNSPrefix}"

  default_node_pool {
    name       = "default"
    node_count = "${var.node_count}"
    vm_size    = "${var.Node_Size}"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}" 
  }

  tags = {
    Environment = "DEV"
  }
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.AZK8SDEV.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.AZK8SDEV.kube_config_raw
}