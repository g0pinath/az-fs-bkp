variable "RGName_AKS" {
  default = "AZ-K8S-INFRA"
}
variable "RGLocation" {
  default = "AUSTRALIA SOUTHEAST"
}

variable "AKSClusterName" {
  default = "AKS-DEV-FS-BKP"
}
variable "AKSDNSPrefix" {
  default = "aksdevfsbkp"
}
variable "node_count" {
  type = number
  default = 1
}

variable "Node_Size" {
  default = "Standard_D2_v2"
}
variable "client_id" {
  default = "a6d4fa75-117e-478d-b370-a634f613b7a5"
}
variable "client_secret" {
  default = "?Xjoi0AEVQ9ggNiLiQMtiB=D-GvEh03@"
}



