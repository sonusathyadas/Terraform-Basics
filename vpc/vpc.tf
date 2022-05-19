
provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

# create custom VPC

resource "aws_vpc" "my_vpc" {
    cidr_block = "172.16.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "VPC-with-Terraform"
    }
}

resource "aws_subnet" "subnet1" {
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = "172.16.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "Subnet1"
    }
}

resource "aws_subnet" "subnet2" {
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = "172.16.2.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "Subnet2"
    }
}

# Create and attach Intenet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "my_vpc-igw"
    }
}

# Create and update the default route table to allow internet traffic using IGW
resource "aws_default_route_table" "vpc_route_table" {
    default_route_table_id = aws_vpc.my_vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "my_vpc-rt"
    }
}

# Create and update default Security group to allow RDP and HTTP
resource "aws_default_security_group" "default" {
  
    vpc_id = aws_vpc.my_vpc.id
    depends_on = [
      aws_vpc.my_vpc
    ]

    ingress {
        protocol  = -1
        self      = true
        from_port = 0
        to_port   = 0
        description = "Default rule"
    }

    ingress {
        protocol  = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
        from_port = 3389
        to_port   = 3389
        description = "Allow RDP"
    }

    ingress {
        protocol  = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
        from_port = 80
        to_port   = 80
        description = "Allow Http"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}