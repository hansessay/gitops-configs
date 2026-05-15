resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "afd-aks-devsecops-dev"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "aks-devsecops-edge"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin_group" "aks" {
  name                     = "aks-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "GET"
    protocol            = "Http"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "aks_ingress" {
  name                          = "aks-ingress-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aks.id

  enabled                        = true
  host_name                      = var.aks_ingress_public_ip
  origin_host_header             = var.aks_ingress_public_ip
  http_port                      = 80
  https_port                     = 443
  certificate_name_check_enabled = false
}

resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "frontend-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aks.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.aks_ingress.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpOnly"
  https_redirect_enabled = true
}