resource "aws_subnet" "road_map_public_subnet_1a" {
  vpc_id                  = aws_vpc.road_map_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = merge({ Name = "road-map-public-subnet-1a-1a" }, var.tags)
}
