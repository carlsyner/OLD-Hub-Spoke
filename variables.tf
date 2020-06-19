variable "location" {
  description = "Location to deploy resources"
  type        = "string"
  default     = "WestEurope"
}

variable "username" {
  description = "Username for Virtual Machines"
  type        = "string"
  default     = "AzureAdmin"
}

variable "password" {
  description = "Password for Virtual Machines"
  type        = "string"
  default     = "Password1234!"
}

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_A2_v2"
}