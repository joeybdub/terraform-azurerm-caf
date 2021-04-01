module "virtual_network_gateways" {
  source   = "./modules/networking/virtual_network_gateways"
  for_each = try(local.networking.virtual_network_gateways, {})

  resource_group_name = module.resource_groups[each.value.resource_group_key].name
  location            = lookup(each.value, "region", null) == null ? module.resource_groups[each.value.resource_group_key].location : local.global_settings.regions[each.value.region]
  public_ip_addresses = local.combined_objects_public_ip_addresses
  diagnostics         = local.combined_diagnostics
  client_config       = local.client_config
  vnets               = local.combined_objects_networking
  global_settings     = local.global_settings
  settings            = each.value
  base_tags           = try(local.global_settings.inherit_tags, false) ? module.resource_groups[each.value.resource_group_key].tags : {}
  depends_on = [
    module.networking.public_ip_addresses
  ]
}

module "virtual_network_gateway_connections" {
  source = "./modules/networking/virtual_network_gateway_connections"
  for_each = {
    for key, value in try(local.networking.virtual_network_gateway_connections, {}) : key => value
    if try(value.virtual_wan, null) == null
  }

  resource_group_name      = module.resource_groups[each.value.resource_group_key].name
  location                 = lookup(each.value, "region", null) == null ? module.resource_groups[each.value.resource_group_key].location : local.global_settings.regions[each.value.region]
  global_settings          = local.global_settings
  settings                 = each.value
  diagnostics              = local.combined_diagnostics
  client_config            = local.client_config
  local_network_gateway_id = try(module.local_network_gateways[each.value.local_network_gateway_key].id, null)
  base_tags                = try(local.global_settings.inherit_tags, false) ? module.resource_groups[each.value.resource_group_key].tags : {}

  virtual_network_gateway_id = coalesce(
    try(module.virtual_network_gateways[each.value.virtual_network_gateway_key].id, null)
  )

  express_route_circuit_id = try(coalesce(
    try(module.express_route_circuits[each.value.express_route_circuit_key].id, null),
    try(module.express_route_circuits[each.value.express_route_circuit.key].id, null),
    try(each.value.express_route_circuit.id, null)
    ),
    null
  )

  authorization_key = try(
    coalesce(
      try(module.express_route_circuit_authorizations[each.value.authorization_key].authorization_key, null),
      try(each.value.express_route_circuit_authorization, null)
    ),
    null
  )

}

module "virtual_hub_er_gateway_connections" {
  source = "./modules/networking/virtual_network_gateway_connections"
  for_each = {
    for key, value in try(local.networking.virtual_network_gateway_connections, {}) : key => value
    if try(value.virtual_wan, null) != null
  }

  resource_group_name      = module.resource_groups[each.value.resource_group_key].name
  location                 = lookup(each.value, "region", null) == null ? module.resource_groups[each.value.resource_group_key].location : local.global_settings.regions[each.value.region]
  global_settings          = local.global_settings
  settings                 = each.value
  diagnostics              = local.combined_diagnostics
  client_config            = local.client_config
  local_network_gateway_id = try(module.local_network_gateways[each.value.local_network_gateway_key].id, null)
  base_tags                = try(local.global_settings.inherit_tags, false) ? module.resource_groups[each.value.resource_group_key].tags : {}

  virtual_network_gateway_id = coalesce(
    try(local.combined_objects_virtual_wans[try(each.value.virtual_wan.lz_key, local.client_config.landingzone_key)][each.value.virtual_wan.key].virtual_hubs[each.value.virtual_wan.virtual_hub.key].er_gateway.id, null),
    try(each.value.express_route_gateway_id, null)
  )

  express_route_circuit_id = try(coalesce(
    try(module.express_route_circuits[each.value.express_route_circuit_key].id, null),
    try(module.express_route_circuits[each.value.express_route_circuit.key].id, null),
    try(each.value.express_route_circuit.id, null)
    ),
    null
  )

  authorization_key = try(
    coalesce(
      try(module.express_route_circuit_authorizations[each.value.authorization_key].authorization_key, null),
      try(each.value.express_route_circuit_authorization, null)
    ),
    null
  )

}

module "local_network_gateways" {
  source              = "./modules/networking/local_network_gateways"
  for_each            = try(local.networking.local_network_gateways, {})
  resource_group_name = module.resource_groups[each.value.resource_group_key].name
  location            = lookup(each.value, "region", null) == null ? module.resource_groups[each.value.resource_group_key].location : local.global_settings.regions[each.value.region]
  global_settings     = local.global_settings
  settings            = each.value
  base_tags           = try(local.global_settings.inherit_tags, false) ? module.resource_groups[each.value.resource_group_key].tags : {}
}
