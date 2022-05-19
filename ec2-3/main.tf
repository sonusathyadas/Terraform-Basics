
# Create an EC2 instance in an existing VPC. 

provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

variable "subnet_id" {
    type = string
    default = "subnet-0b62ac4368e058377" # id of the existing subnet
}
#Create EC2 on custom VPC
resource "aws_network_interface" "web_server1_nic" {
    
    subnet_id   = var.subnet_id
    tags = {
        Name = "Web-Server-1-NIC"
    }
}

resource "aws_instance" "web_server1" {
    ami           = "ami-09ed03e97033b6d21"
    instance_type = "t2.micro"
    network_interface {
        network_interface_id = aws_network_interface.web_server1_nic.id
        device_index = 0
    }
    key_name = "EC2-Key"
    tags = {
        Name = "DemoWebServer"
    }
}
