output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "vm" {
  value = azurerm_linux_virtual_machine.server
}

output "secrets" {
  value = data.onepassword_item.secrets
}
