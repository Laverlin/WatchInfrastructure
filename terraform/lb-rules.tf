resource "azurerm_lb_rule"  "lb-rules"{
  for_each = {
    HTTP = { protocol = "Tcp", fr-port = 80, bk-port = 80 }
    HTTPS = { protocol = "Tcp", fr-port = 443, bk-port = 443 }
    UDP-500 = { protocol = "Udp", fr-port = 500, bk-port = 30500 }
    UDP-4500 = { protocol = "Udp", fr-port = 4500, bk-port = 30450 }
  }

  loadbalancer_id                = azurerm_lb.lb.id
  name                           = each.key
  protocol                       = each.value.protocol
  frontend_port                  = each.value.fr-port
  backend_port                   = each.value.bk-port
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.addr_pool.id]
  depends_on = [azurerm_lb_backend_address_pool.addr_pool, azurerm_lb.lb]
  
}

########################################
#          NAT Rules
########################################

/// KubeCtl
///
resource "azurerm_lb_nat_rule" "kubectl_rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "KubeCtl"
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  depends_on = [azurerm_lb.lb]
}

resource "azurerm_network_interface_nat_rule_association" "nic_nat_kubectl" {
  network_interface_id  = azurerm_network_interface.nic[0].id
  ip_configuration_name = azurerm_network_interface.nic[0].ip_configuration[0].name 
  nat_rule_id           = azurerm_lb_nat_rule.kubectl_rule.id
    depends_on = [azurerm_network_interface.nic]
}