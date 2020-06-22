variable "location" {
  description = "Location to deploy resources"
  type        = string
  default     = "WestEurope"
}

variable "username" {
  description = "Please enter Username for the Virtual Machines"
  type        = string
  default     = "AzureAdmin"
}

variable "password" {
  description = "Password for Virtual Machines"
  type        = string
  }

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_A2_v2"
}