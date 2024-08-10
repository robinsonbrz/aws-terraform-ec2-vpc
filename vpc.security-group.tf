resource "aws_security_group" "road_map_security_group_allow_ssh" {
  name        = "security_group_allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.road_map_vpc.id

  tags = merge({ Name = "road-map-security-group-allow-ssh" }, var.tags)
}

# Ingress Rule
resource "aws_vpc_security_group_ingress_rule" "road_map_security_group_ingress_rule_allow_ssh_ipv4" {
  security_group_id = aws_security_group.road_map_security_group_allow_ssh.id
  # Boa prática seria adicionar o ip de seu computador restringindo tentativas externas
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}


# Eggress Rule
resource "aws_vpc_security_group_egress_rule" "road_map_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.road_map_security_group_allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

