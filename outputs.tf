output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "customer_url" {
  value = "http://${azurerm_public_ip.pip.ip_address}/customer/frontend/login.html"
}

output "staff_url" {
  value = "http://${azurerm_public_ip.pip.ip_address}/staff/frontend/login.html"
}

output "warehouse_url" {
  value = "http://${azurerm_public_ip.pip.ip_address}/warehouse/frontend/login.html"
}

output "executive_url" {
  value = "http://${azurerm_public_ip.pip.ip_address}/executive/frontend/login.html"
}