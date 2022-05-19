
provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

resource "aws_instance" "web_server1" {
    ami           = "ami-09ed03e97033b6d21"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    tags = {
        Name = "DemoWebServer"
    }
}
