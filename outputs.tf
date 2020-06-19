output "vm_ids" {
  description = "Virtual machine ids created."
  value       = concat(azurerm_virtual_machine.vm-windows.*.id)
}

output "public_ip_address" {
  description = "The actual ip address allocated for the resource."
  value       = azurerm_public_ip.vm.*.ip_address
}