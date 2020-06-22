variable "location" {
  description = "Location to deploy resources"
  type        = string
  default     = "WestEurope"
}

variable "username" {
  description = "Username for Virtual Machines"
  type        = string
  default     = "AzureAdmin"
}

variable "password" {
  description = "Please enter a Password for the Virtual Machines"
  type        = string
    }

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_A2_v2"
}