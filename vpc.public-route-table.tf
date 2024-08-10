resource "aws_route_table" "road_map_public_route_table" {
  vpc_id = aws_vpc.road_map_vpc.id

  route {
    # Acesso de todos os IPs para a internet
    cidr_block = "0.0.0.0/0"
    # Apontando para o gateway da internet
    gateway_id = aws_internet_gateway.road_map_ig.id
  }
  tags = merge({ Name = "road-map-public-route-table" }, var.tags)
}

resource "aws_route_table_association" "road_map_public_route_table_association" {
  subnet_id      = aws_subnet.road_map_public_subnet_1a.id
  route_table_id = aws_route_table.road_map_public_route_table.id
}
