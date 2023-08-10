provider "aws" {
  region = "eu-west-1"
}

//VPC creation

resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "${var.prefix}-vpc-test"
 }
}

//Just by applying this configuration, since we are creating a VPC – a main Route table, and main Network ACL is also created.
//The VPC is also associated with a pre-existing DHCP option set.data "" "name" {}We will take note of this as we would need this information later.

//Creation of public and private subnets per az

resource "aws_subnet" "public_subnets" {
 count             = length(var.public_subnet_cidrs)
 vpc_id            = aws_vpc.main.id
 cidr_block        = element(var.public_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "${var.prefix}-public-subnet-${count.index + 1}"
 }
}
 
resource "aws_subnet" "private_subnets" {
 count             = length(var.private_subnet_cidrs)
 vpc_id            = aws_vpc.main.id
 cidr_block        = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "${var.prefix}-private-subnet-${count.index + 1}"
 }
}

//Creating separate resource blocks for public and private subnets gives us the flexibility to manage them in Terraform IaC.
//Since we have subnet CIDRs in the form of a list of strings, we have leveraged the length property to create a corresponding number of subnets

//Gateway creation
resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "${var.prefix}-gateway"
 }
}

//We have already associated this IG with the VPC we created before by specifying the VPC id attribute

//Second route table creation
//At this moment, even though the subnets are called Public and Private, they are all private. To make the subnets named “Public” public, we have to create routes using IGW which will enable the traffic from the Internet to access these subnets.
//As a best practice, we create a Second route table and associate it with the same VPC as shown in the below resource block. Note that we have also specified the route to the internet (0.0.0.0/0) using our IGW.

resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "${var.prefix}-second-route-table"
 }
}

//We have to explicitly associate all the public subnets with the second route table to enable internet access on them.

resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}


resource "aws_security_group" "mi_grupo_de_seguridad" {
  name   = "${var.prefix}-tf-sg"
  vpc_id = aws_vpc.main.id
 
  ingress {
  description = "SSH"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 ingress { 
  description = "HTTP"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 ingress {
  description = "TCP"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }

}

resource "tls_private_key" "tls_pk" {
 algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {
 key_name = "${var.prefix}-tls-key"
 public_key = "${tls_private_key.tls_pk.public_key_openssh}"
 depends_on = [
  tls_private_key.tls_pk
 ]
}

resource "local_file" "key" {
 content = "${tls_private_key.tls_pk.private_key_pem}"
 filename = "${var.prefix}-tls-key.pem"
 file_permission ="0400"
 depends_on = [
  tls_private_key.tls_pk
 ]
}
resource "aws_instance" "ec2_main" {
  ami             = "ami-0aef57767f5404a3c"
  instance_type   = "t2.micro"
  
  # refering key which we created earlier
  key_name        = "${aws_key_pair.generated_key.key_name}"
  subnet_id                   = "${aws_subnet.public_subnets[0].id}"
  vpc_security_group_ids      = [aws_security_group.mi_grupo_de_seguridad.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.prefix}-ec2-cl-test"
  }
}
