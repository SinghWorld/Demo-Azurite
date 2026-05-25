output "vm_id" {
  description = "The ID of the created VM"
  value       = try(azurerm_linux_virtual_machine.main.id, "Not provisioned (local testing)")
}

output "vm_name" {
  description = "The name of the created VM"
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = try(azurerm_public_ip.main.ip_address, "Not assigned (local testing)")
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "resource_group_name" {
  description = "The resource group name"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_id" {
  description = "The virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "network_interface_id" {
  description = "The network interface ID"
  value       = azurerm_network_interface.main.id
}

output "terraform_state_location" {
  description = "Location of Terraform state"
  value       = "Azurite local storage (http://127.0.0.1:10000)"
}
