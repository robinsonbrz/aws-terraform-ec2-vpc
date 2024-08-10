# Tutorial Criação de EC2 com VPC e acesso SSH com Terraform

## Objetivo 

Criar um ambiente básico EC2 na nuvem AWS utilizando IaC Terraform.

Ambiente básico com procedimento guiado com principais comandos apontados em documentação.

### Recursos alocados com Terraform:

- AWS VPC
- AWS internet gateway
- AWS security group
- AWS subnet pública com acesso SSH, à instância EC2.
- AWS EC2 instance
- Criação de chave pem para acesso a instância


## Pré requisitos:

- Usuário IAM com privilégios suficientes aos recursos utilizados na AWS
    - **Access Key Id** e **Secret access Key** do usuário com privilégios AWS
- **Terraform** instalado em sua estação de trabalho:
    - Para instalar **www.terraform.io** clicar em download CLI
        - Baixar e instalar a versão de acordo com o seu SO (preferível trabalhar com Linux).
        - Confirmar a instalação com ```terraform -v```
- Ambiente Linux ( Opcional, deverá adaptar os procedimentos caso utilize Windows )
- VsCode - Opcional
    - HashiCorp Terraform extensão do VsCode - Opcional

## Acesso ao console AWS

Verificar **Access Key Id** e **Secret access Key**

Salvar chaves em  "~/.aws/credentials"



## Iniciando na documentação Terraform

www.registry.terraform.io/browse/providers

Documentação para AWS provider

https://registry.terraform.io/providers/hashicorp/aws/latest/docs


Criar arquivo main.tf

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"

  # em profile utilizamos o nome do profile configurado com AWS config
  # no Linux este arquivo fica em na pasta de usuário: ~/.aws/credentials
  # o mais comum é o default, mas podemos criar outras contas AWS
  profile = RoadMap

  # Aqui também poderíamos utilizar o access_key e secret_key hardcoded
  # mas isso não é uma boa prática, pois expõe as credenciais
    # access_key = "sua access_key caso não utilize profile"
    # secret_key = "sua secret_key caso não utilize profile"

```

Neste momento podemos rodar o terraform e verificar se estamos no caminho certo

Na pasta com os arquivos Terraform, digite terraform init

Isto fará um download dos recursos necessários para o provider selecionado e também validará o arquivo main.tf

Agora vamos criar nossa VPC.

Seria possível configurar isto em um arquivo main.tf mas vamos organizar em arquivos separados.

criaremos um arquivo vpc.tf conforme a documentação do Terraform pesquisando por aws_vpc


```
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}
```

Podemos criar um arquivo variables.tf para configurações comuns
https://developer.hashicorp.com/terraform/language/values/variables






criaremos um arquivo vpc.public-subnet.tf conforme a documentação do Terraform pesquisando por aws_vpc

```
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}
```

Associar a VPC do projeto

Setar as variáveis 
  availability_zone       = "us-east-1a"

  map_public_ip_on_launch = true  ensures that any instances launched in this subnet will automatically receive a public IP address, making them accessible from the internet.

## internet gateway

criaremos um arquivo vpc.internet_gateway.tf conforme a documentação do Terraform pesquisando por aws_internet_gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

Associar a VPC do projeto

## Public rout table

criar um arquivo vpc.route-table.tf conforme a documentação do Terraform pesquisando por aws_route_table. Será um resource dentro de VPC

```
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.example.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  }

  tags = {
    Name = "example"
  }
}
```

Também anexar um route table association, se basear na documentação

```
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.foo.id
  route_table_id = aws_route_table.bar.id
}

```


## Security group

Pesquisar aws_security_group em resource de VPC na documentação Terraform

```
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
```

Essa foi uma configuração mínima e básica de rede VPC para acomodar a nossa instância EC2

## Instância EC2

Na documentação Terraform pesquisar por aws_instance

criar um arquivo chamado ec2.instance.tf

E definir a imagem de criação da instância EC2

Pesquisar imagens públicas em AMI
https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images

Apontar para a subnet_id recem criada

Apontar para o security group

Mostrar os rastros de Cloud Trail

# Criar EC2 Key pair

Criar arquivo ec2.key-pair.tf
Em Terraform pesquisar key_pair

Existem pelo menos duas formas de configurar um acesso a sua instância EC2

- criando as chaves .pem
- adicionando a chave pública de seu computador Linux  
    - Isso escreve no arquivo authorized_keys da instância


A primeira forma é para quando temos um par de chaves ssh de nosso computador na pasta ~/.ssh/ .

Informando a instância que computadores que possuam a chave privada, da chave pública informada pode acessar a instância.

Isso funciona em Linux / MAC / Windows mais recentes


Para isso criamos um arquivo ec2.key-pair.tf
```
  # ~/.ssh/  - Linux Home Path to ssh key pair files
  public_key = file("~/.ssh/id_rsa.pub")
```

E adicionamos ao atributo key_name do resource "aws_instance" no arquivo ec2.instance.tf 
  key_name        = aws_key_pair.deployer_ssh_key_pair.key_name

Com isso já será possível acessar a instância EC2, utilizando o ip público fornecido

```
ssh -i ~/.ssh/id_rsa ubuntu@54.198.110.162
```
Veja que no comando acima utilizamos a mesma chave ~/.ssh/id_rsa para assinar a conexão ssh

#######################################

A outra forma é criar e salvar o arquivo .pem dessa instância para acesso posterior

Também poderíamos utilizar uma private_key chave .pem criada anteriormente na AWS

Mas nesse exemplo criamos e exportamos para o output do Terraform

Este nétodo é mais flexível porque permite que utilizemos a chave .pem (private_key da instância) em qualquer computador que tenha o ip na lista de permissão do security group


Para isso na documentação do terraform procuraremos em Provider -> TLS -> Documentação

Procurar por tls_private_key

Escolher a opção do algoritmo RSA e colar no arquivo ec2.keuy-pair.tf

```
# RSA key of size 4096 bits
resource "tls_private_key" "rsa-4096-example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "deployer_ssh_key_pair" {
  key_name = "road-map-private-key"
  public_key = tls_private_key.road_map_private_key.public_key_openssh
}

```

Agora utilizaremos o recurso outputs do terraform criando um arquivo outputs.tf

https://developer.hashicorp.com/terraform/language/values/outputs

Pesquisar por "output values hashicorp" no Google

e copiar o template que permite criar valores de output após a aplicação do terraform

Nesse caso capturaremos a private_key da instância

```
output "instance_ip_addr" {
  value = aws_instance.server.private_ip
}
```

Necessário devido a um novo provider ter sido acrescentado
```
terraform init -upgrade

terraform validate

terraform apply

```
yes


Enquanto a AWS provisiona vamos preparar a chave pem

mkdir em ~/.ssh/keys-repo/

Executar no terminal
terraform output -raw road_map_private_key > ~/.ssh/keys-repo/road-map-private-key.pem

ls -al ~/.ssh/keys-repo/road-map-private-key.pem

chmod 400 ~/.ssh/keys-repo/road-map-private-key.pem

ls -al ~/.ssh/keys-repo/road-map-private-key.pem

Acesso a instância
ssh -i ~/.ssh/keys-repo/road-map-private-key.pem ubuntu@52.54.180.220

verificando a chave instalada em 

nano ~/.ssh/authorized_keys

terraform destroy

yes




