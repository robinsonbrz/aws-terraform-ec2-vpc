# Configuração da imagem de criação da instância EC2
data "aws_ami" "ubuntu" {
  most_recent = true

  # Filtrando a busca pela imagem Ubuntu mais recente
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "road_map_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.road_map_public_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.road_map_security_group_allow_ssh.id]
  #  key_name               = aws_key_pair.deployer_ssh_key_pair.key_name
  key_name = aws_key_pair.road_map_ssh_key_pair.key_name
  tags     = merge({ Name = "road-map-ec2-instance" }, var.tags)
}
