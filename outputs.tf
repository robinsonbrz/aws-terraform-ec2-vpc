output "road_map_private_key" {
  sensitive = true
  value     = tls_private_key.road_map_private_key.private_key_pem
}
