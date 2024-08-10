# Acesso por chave .pem
resource "tls_private_key" "road_map_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# segunda opção de acesso a instância
resource "aws_key_pair" "road_map_ssh_key_pair" {
  key_name   = "road-map-private-key"
  public_key = tls_private_key.road_map_private_key.public_key_openssh
}



# # segunda opção de acesso a instância 
# resource "aws_key_pair" "deployer_ssh_key_pair" {
#   key_name = "id_rsa"
#   # ~/.ssh/  - Linux Home Path to ssh key pair files
#   public_key = file("~/.ssh/id_rsa.pub")
# }