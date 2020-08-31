provider "random" {}

module "tags_network" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "network"
  }
}

module "tags_phi" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "phi-devops-bootcamp"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "phi"
  }
}

resource "aws_vpc" "k8s_lab" {
  cidr_block           = "10.0.0.0/16"
  tags                 = module.tags_network.tags
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "lab_gateway" {
  vpc_id = aws_vpc.k8s_lab.id
  tags   = module.tags_network.tags
}

resource "aws_route" "lab_internet_access" {
  route_table_id         = aws_vpc.k8s_lab.main_route_table_id
  gateway_id             = aws_internet_gateway.lab_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "phi" {
  vpc_id                  = aws_vpc.k8s_lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = module.tags_phi.tags
}

resource "aws_security_group" "phi" {
  vpc_id = aws_vpc.k8s_lab.id
  tags   = module.tags_phi.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
	
	ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
	ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_id" "keypair" {
  keepers = {
    public_key = file(var.public_key_path)
  }

  byte_length = 8
}

resource "aws_key_pair" "lab_keypair" {
  key_name   = format("%s_keypair_%s", var.name, random_id.keypair.hex)
  public_key = random_id.keypair.keepers.public_key
}

data "aws_ami" "latest_phi" {
  most_recent = true
  owners      = ["772816346052"]

  filter {
    name   = "name"
    values = ["phi-sandbox*"]
  }
}

resource "aws_instance" "phi" {
  ami                    = data.aws_ami.latest_phi.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.phi.id
  vpc_security_group_ids = [aws_security_group.phi.id]
  key_name               = aws_key_pair.lab_keypair.id

  root_block_device {
    volume_size = 100
    volume_type = "gp2"
  }
/*
  provisioner "remote-exec" {
		connection {
			type        = "ssh"
			user        = "ubuntu"
			host        = self.public_ip
			private_key = file(var.private_key_path)
			}

    inline = ["cd /home/ubuntu/ && git clone https://github.com/OZB96/k8s-jenkins && cd k8s-jenkins && ./jenkins.sh"]
	}
	
  tags = module.tags_phi.tags  */
}
