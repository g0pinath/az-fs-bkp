variable "RGName_AKS" {
  default = ""
}
variable "RGLocation" {
  default = ""
}

variable "AKSClusterName" {
  default = ""
}
variable "AKSDNSPrefix" {
  default = ""
}
variable "node_count" {
  type = number
  default = 1
}

variable "Node_Size" {
  default = "Standard_D2_v2"
}
variable "client_id" {
  default = ""
}
variable "client_secret" {
  default = ""
}



