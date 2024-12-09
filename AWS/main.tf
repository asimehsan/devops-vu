provider "aws" {
  region = "us-west-1"
}


# VPC Definition
resource "aws_vpc" "vpc_by_iac" {
  cidr_block           = "100.100.100.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-by-iac"
  }
}


# Fetch Availability Zones
data "aws_availability_zones" "available" {}

# Output AZ Names
output "availability_zone_names" {
  value = data.aws_availability_zones.available.names
}

# Internet Gateway
resource "aws_internet_gateway" "ig_iac" {
  vpc_id = aws_vpc.vpc_by_iac.id
  tags = {
    Name = "main-internet-gateway"
  }
}

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_by_iac.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_iac.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc_by_iac.id
  cidr_block              = cidrsubnet(aws_vpc.vpc_by_iac.cidr_block, 4, count.index * 2)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc_by_iac.id
  cidr_block              = cidrsubnet(aws_vpc.vpc_by_iac.cidr_block, 4, count.index * 2 + 1)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc_by_iac.id
  tags = {
    Name = "private-route-table"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}


# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip" {
  count = length(data.aws_availability_zones.available.names)
  domain = "vpc" 
  tags = {
    Name = "nat-eip-${count.index}"
  }
}


# NAT Gateways
resource "aws_nat_gateway" "nat_gw" {
  count         = length(data.aws_availability_zones.available.names)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "nat-gateway-${count.index}"
  }
}



# Key Pair
resource "aws_key_pair" "iac_key_pair" {
  key_name   = "iac-key-pair"
  public_key = file("C:\\Users\\Administrator\\.ssh\\id_rsa.pub")
}


# Security Group for SSH access
resource "aws_security_group" "web_sg" {
  name        = "web-instance-sg"
  description = "Allow SSH access from anywhere"
  vpc_id      = aws_vpc.vpc_by_iac.id  # Use your VPC ID

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from all IPs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-instance-sg"
  }
}


# EC2 Instance in Public Subnet
resource "aws_instance" "web_instance" {
  ami           = "ami-0657605d763ac72a8"  # Replace with your AMI ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.iac_key_pair.key_name

  subnet_id = aws_subnet.public[0].id  # Choose the first public subnet (us-west-1a)

  associate_public_ip_address = true

  # Attach Security Group
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "web-instance2"
  }
}

output "web_instance_public_ip" {
  value = aws_instance.web_instance.public_ip
  description = "The public IP address of the web instance"
}


# Security Group for SSH and ICMP
resource "aws_security_group" "ssh_icmp_sg" {
  name        = "ssh-icmp-sg"
  description = "Allow SSH and ICMP access from anywhere"
  vpc_id      = aws_vpc.vpc_by_iac.id  # Use your VPC ID

  # Ingress rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from all IPs
  }

  # Ingress rule for ICMP (ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow ICMP from all IPs
  }

  # Egress rule for all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-icmp-security-group"
  }
}


# EC2 Instance in Private Subnet
resource "aws_instance" "db_instance" {
  ami           = "ami-0657605d763ac72a8"  # Replace with your AMI ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.iac_key_pair.key_name

  subnet_id = aws_subnet.private[0].id  # Choose the first public subnet (us-west-2a)

  associate_public_ip_address = false

  # Attach Security Group
  vpc_security_group_ids = [aws_security_group.ssh_icmp_sg.id]

  tags = {
    Name = "db-instance"
  }
}

output "db_instance_private_ip" {
  value = aws_instance.db_instance.private_ip
  description = "The private IP address of the db instance"
}
