variable "location" {
  description = "Location of the network"
  default     = "CanadaCentral"
}

variable "onpremlocation" {
  description = "Location of the network"
  default     = "CentralUS"
}

variable "username" {
  description = "Username for Virtual Machines"
  default     = "AzureAdmin"
}

variable "password" {
  description = "Password for Virtual Machines"
  default     = "Password1234!"
}

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_A2_v2"
}