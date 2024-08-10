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

Neste formato:

```
[RoadMap]
# This key identifies your AWS account.
aws_access_key_id = A############D#F##G
aws_secret_access_key = 2l4j243lkjdP2Sx3NuO9GhHOçdasç~çR/h

```




## Iniciando na documentação Terraform

www.registry.terraform.io/browse/providers

Documentação para AWS provider

https://registry.terraform.io/providers/hashicorp/aws/latest/docs


# Iniciando com o Terraform

Acessar a documentação terraform e  pelo provider AWS

Já teremos a configuração do provider


## Main.tf

Configurações inicias e profile

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

## Inicializando o Terraform 

Neste momento podemos rodar o terraform e verificar se estamos no caminho certo

Na pasta com os arquivos Terraform, digite ```terraform init```

Isto fará um download dos recursos necessários para o provider selecionado e também validará o arquivo main.tf



## VPC.

Criaremos um arquivo ```vpc.tf``` conforme a documentação do Terraform pesquisando por aws_vpc

```
resource "aws_vpc" "road_map_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = merge({ Name = "road-map-vpc" }, var.tags)
}
```

Podemos criar um arquivo variables.tf para configurações comuns
https://developer.hashicorp.com/terraform/language/values/variables

## Variables

Criar um arquivo ```varibles.tf```
```
variable "tags" {
  type = object({
    Project     = string,
    Environment = string
  })
  default = {
    Project     = "road-map-ec2-terraform"
    Environment = "dev"
  }
}
```

## Public subnet

Criar um arquivo ```vpc.public-subnet.tf``` conforme a documentação do Terraform pesquisando por aws_public_subnet

```
resource "aws_subnet" "road_map_public_subnet_1a" {
  vpc_id                  = aws_vpc.road_map_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = merge({ Name = "road-map-public-subnet-1a-1a" }, var.tags)
}
```

Associar a VPC do projeto

Setar as variáveis 
  availability_zone       = "us-east-1a"

  map_public_ip_on_launch = true  ensures that any instances launched in this subnet will automatically receive a public IP address, making them accessible from the internet.

## Internet Gateway

Criar um arquivo ```vpc.internet_gateway.tf``` conforme a documentação do Terraform pesquisando por aws_internet_gateway

```
resource "aws_internet_gateway" "road_map_ig" {
  vpc_id = aws_vpc.road_map_vpc.id
  tags   = merge({ Name = "road-map-vpc-ig" }, var.tags)
}
```

Associar a VPC do projeto

## Public Route Table

Criar um arquivo ```vpc.public-route-table.tf``` conforme a documentação do Terraform pesquisando por aws_route_table. Será um resource dentro de VPC

```
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
```

## Security group

Criar o arquivo ```vpc.security-group.tf```

Pesquisar aws_security_group em resource de VPC na documentação Terraform aws_security_group

```
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
```

Essa foi uma configuração mínima e básica de rede VPC para acomodar a nossa instância EC2.

## Instância EC2

Criar um arquivo chamado ```ec2.instance.tf``` para definir a imagem de criação da instância EC2

Na documentação Terraform pesquisar por aws_instance

Consultando imagens públicas em AMI
https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images

- Apontar para a subnet_id recem criada

- Apontar para o security group

Executar ```terraform apply``` e verificar os rastros de Cloud Trail ( opcional ) ```terraform destroy```

## Criar EC2 Keys

Existem pelo menos duas formas de configurar um acesso a sua instância EC2

- criando a chave .pem da instância EC2
- adicionando a chave pública de seu computador Linux no arquivo authorized_keys da instância

Criar arquivo ```ec2.key-pair.tf```

Em Terraform pesquisar key_pair

## Método de acesso adicionando nossa chave pública em Authorized keys

A primeira forma é para quando temos um par de chaves ssh de nosso computador na pasta ```~/.ssh/```

***Isso exige um passo que não está descrito aqui, que é criar um par de chaves SSH***

### Informando a instância que computadores que possuam a chave privada, da chave pública informada pode acessar a instância.

***Isso funciona em Linux / MAC / Windows mais recentes***


Para isso criamos um arquivo ```ec2.key-pair.tf```

```
resource "aws_key_pair" "deployer_ssh_key_pair" {
  key_name = "id_rsa"
  # ~/.ssh/  - Linux Home Path to ssh key pair files
  public_key = file("~/.ssh/id_rsa.pub")
}
```

E adicionamos ao atributo key_name do resource "aws_instance" no arquivo ec2.instance.tf 
  key_name        = aws_key_pair.deployer_ssh_key_pair.key_name

Ao aplicar o ```terraform apply``` já poderemos acessar a instância EC2, utilizando o ip público fornecido

```
ssh -i ~/.ssh/id_rsa ubuntu@54.198.110.162
```
Veja que no comando acima utilizamos a mesma chave ~/.ssh/id_rsa para assinar a conexão ssh

## Método de acesso baixando a chave .pem da instância

A outra forma é criar e salvar o arquivo .pem dessa instância para acesso posterior

Nesse exemplo criamos e exportamos para o output do Terraform

Este nétodo é mais flexível porque permite que utilizemos a chave .pem (private_key da instância) em qualquer computador que tenha o ip na lista de permissão do security group


Para isso na documentação do terraform procuraremos em Provider -> TLS -> Documentação

Procurar por tls_private_key

Escolher a opção do algoritmo RSA e colar no arquivo ```ec2.key-pair.tf```

```
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
```

Agora utilizaremos o recurso outputs do terraform criando um arquivo ```outputs.tf```

https://developer.hashicorp.com/terraform/language/values/outputs

Pesquisar por ```output values hashicorp``` no Google

e copiar o template que permite criar valores de output após a aplicação do terraform

Nesse caso capturaremos a private_key da instância 

Arquivo ```outputs.tf```

```
output "road_map_private_key" {
  sensitive = true
  value     = tls_private_key.road_map_private_key.private_key_pem
}
```

## Inicializando a instância finalizada pelo Terraform

```
terraform fmt

terraform init -upgrade

terraform validate

terraform apply
```

confirmar com ```yes```

Enquanto a AWS provisiona os recursos vamos preparar a chave pem

```mkdir ~/.ssh/keys-repo/```

Executar no terminal após a alocação dos recursos

```terraform output -raw road_map_private_key > ~/.ssh/keys-repo/road-map-private-key.pem```

```ls -al ~/.ssh/keys-repo/road-map-private-key.pem```


```chmod 400 ~/.ssh/keys-repo/road-map-private-key.pem```

```ls -al ~/.ssh/keys-repo/road-map-private-key.pem```

### Acesso a instância

Verificar o ip gerado no console na instância EC2

``` ssh -i ~/.ssh/keys-repo/road-map-private-key.pem ubuntu@52.54.180.220```

Verificando a chave instalada em 

```
nano ~/.ssh/authorized_keys

terraform destroy
```

Confirmar com ```yes```