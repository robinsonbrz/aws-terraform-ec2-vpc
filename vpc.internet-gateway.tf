resource "aws_internet_gateway" "road_map_ig" {
  vpc_id = aws_vpc.road_map_vpc.id
  tags   = merge({ Name = "road-map-vpc-ig" }, var.tags)
}