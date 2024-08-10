resource "aws_vpc" "road_map_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = merge({ Name = "road-map-vpc" }, var.tags)
}