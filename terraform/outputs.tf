#IP Public
output "public_ip" {
  value = azurerm_public_ip.aggIpPublic.ip_address
}
#User ssh mv
output "user_ssh" {
  value = var.adminuser
}
#Pss ssh mv
output "pass_ssh" {
  value = var.admin_pass
}