provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

#################
#Configuring VPC#
#################

resource "aws_vpc" "ee_vpc" {
  cidr_block  		   = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "ee_vpc"
  }
}

#Create internet gateway
resource "aws_internet_gateway" "ee_igw" {
  vpc_id = aws_vpc.ee_vpc.id
  tags = {
    Name = "ee_igw"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "ee_internet_access" {
  route_table_id         = aws_vpc.ee_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ee_igw.id
}

############################
#Configuring public subnet#
############################

#Create public route table
resource "aws_route_table" "ee_public_RT" {
  vpc_id       = aws_vpc.ee_vpc.id
  route {
	cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.ee_igw.id
  }
  tags = {
    Name = "ee_public_RT"
  }
}

#Creating public subnet
resource "aws_subnet" "ee_public_subnet" {
  vpc_id                  = aws_vpc.ee_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "ee_public_subnet"
  }
}

#Associate public route table with public subnet
resource "aws_route_table_association" "ee_RT_to_pub_subnet"{
    subnet_id      = aws_subnet.ee_public_subnet.id
    route_table_id = aws_route_table.ee_public_RT.id
}

############################
#Configuring private subnet#
############################

#Create EIP for NAT gateway
resource "aws_eip" "nat_eip" {
  vpc      = true
  tags = {
    Name = "nat_eip"
  }
}

#Create NAT gateway
resource "aws_nat_gateway" "ee_nat_gw" {
	allocation_id = aws_eip.nat_eip.id
	subnet_id     = aws_subnet.ee_public_subnet.id
	tags = {
    Name = "ee_nat_gw"
  }
}

#Create private route table
resource "aws_route_table" "ee_private_RT" {
  vpc_id       = aws_vpc.ee_vpc.id
  route {
	cidr_block = "0.0.0.0/0"
	gateway_id = aws_nat_gateway.ee_nat_gw.id
  }
  tags = {
    Name = "ee_private_RT"
  }
}

#Create private subnet
resource "aws_subnet" "ee_private_subnet" {
  vpc_id                  = aws_vpc.ee_vpc.id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false
  tags = {
    Name = "ee_private_subnet"
  }
}

#Associate private route table with private subnet
resource "aws_route_table_association" "ee_RT_to_priv_subnet"{
    subnet_id      = aws_subnet.ee_private_subnet.id
    route_table_id = aws_route_table.ee_private_RT.id
}

#############################
#Configuring public instance#
#############################

#Create Security group for public instance
resource "aws_security_group" "ee_public_sg" {
    vpc_id = aws_vpc.ee_vpc.id
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
		#Allowing egress traffic to all
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	ingress { #For Jenkins
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	tags = {
    Name = "ee_public_sg"
  }
}

#Upload the keypair for logging to instances
resource "aws_key_pair" "ee_login_key" {
  key_name   = "ee_login_key"
  public_key = file(var.public_key_path)
}

#Create the aws instance in public subnet
resource "aws_instance" "ee_public_instance" {
  ami             			  = var.ubuntu_ami
  instance_type   			  = "t2.micro"
  key_name        			  = aws_key_pair.ee_login_key.key_name
  security_groups		 	  = [aws_security_group.ee_public_sg.id]
  subnet_id                   = aws_subnet.ee_public_subnet.id
  associate_public_ip_address = true
  
  connection {
	type	 	= "ssh"
	user     	= "ubuntu"
	host     	= self.public_ip
	private_key = file(var.private_key_path)
  }
  provisioner "remote-exec" {
    inline = [
	  "sudo rm -f /var/lib/dpkg/lock-frontend && sudo rm -f /var/lib/apt/lists/lock", # Need to clear apt locks just in case it is being held by some ui process
	  "sudo apt-get -y update",
	  "sudo apt-get -y upgrade",
	  "sudo apt-get install -y python",
	  "sudo apt-add-repository -y ppa:ansible/ansible",
	  "sudo apt-get -y update",
	  "sudo apt-get install -y ansible",
	  "sudo apt install -y default-jre",
	  "wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -",
	  "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
	  "sudo apt-get -y update",
	  "sudo apt install -y jenkins",
	  "sudo systemctl start jenkins",
	  "sudo ufw allow 8080"
   ]
  }
  provisioner "file" {
    source      = var.private_key_path
    destination = "/home/ubuntu/id_rsa"
  }
  provisioner "file" {
    source      = var.docker_playbook_path
    destination = "/home/ubuntu/install_docker.yaml"
  }
  tags = {
    Name = "ee_public_instance"
  }
}

##############################
#Configuring private instance#
##############################

#Create Security group for private instance
resource "aws_security_group" "ee_private_sg" {
    vpc_id = aws_vpc.ee_vpc.id
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
		#Allowing egress traffic to all
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["172.20.0.0/16"]
    }
	tags = {
    Name = "ee_private_sg"
  }
}

#Create the aws instance in private subnet
resource "aws_instance" "ee_private_instance" {
  ami             			  = var.ubuntu_ami
  instance_type   			  = "t2.micro"
  key_name        			  = aws_key_pair.ee_login_key.key_name
  security_groups		 	  = [aws_security_group.ee_private_sg.id]
  subnet_id                   = aws_subnet.ee_private_subnet.id
  associate_public_ip_address = false
  tags = {
    Name = "ee_private_instance"
  }
}

#Install docker on private instance
resource "null_resource" "docker_provisioner" {
  provisioner "remote-exec" {
    inline = [
	  #Create ansible hosts file
	  "echo '[all]' > /home/ubuntu/hosts_file",
	  "echo ${aws_instance.ee_private_instance.private_ip} >> /home/ubuntu/hosts_file",
	  "chmod 600 /home/ubuntu/id_rsa",
	  #Run docker playbook
	  "ansible-playbook -i /home/ubuntu/hosts_file /home/ubuntu/install_docker.yaml"
    ]
	
	connection {
		type	 	= "ssh"
		user     	= "ubuntu"
		host     	= aws_instance.ee_public_instance.public_ip
		private_key = file(var.private_key_path)
	}
  }
  depends_on = [aws_instance.ee_private_instance, aws_instance.ee_public_instance]
}
