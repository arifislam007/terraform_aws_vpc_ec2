# Create a custom VPC with the name "myVPC03"
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"  # Change this to your desired CIDR block

  tags = {
    Name = "myVPC03"
  }
}

# Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "custom_igw" {
  vpc_id = aws_vpc.custom_vpc.id
}

# Create a public subnet within the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"  # Change this to your desired CIDR block for the public subnet
  map_public_ip_on_launch = true           # Associate public IP addresses with instances in this subnet
}

# Create a default route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # Default route for all traffic
    gateway_id = aws_internet_gateway.custom_igw.id
  }
}

# Associate the default route table with the public subnet
resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a security group to allow SSH access (you can customize the ingress rules as needed)
resource "aws_security_group" "custom_sg" {
  name        = "custom-security-group"
  description = "Allow SSH and other necessary ports"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add more ingress rules if required for your application
}

# Launch the EC2 instance in the public subnet and attach the security group
resource "aws_instance" "custom_ec2_instance" {
  ami           = "ami-0ebfd941bbafe70c6"  # Change this to the new AMI ID
  instance_type = "t2.micro"               # Change this to your desired instance type
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.custom_sg.id]

  associate_public_ip_address = true  # Assign a public IP to the instance

  key_name = "mylabkey"  # Specify the key pair to associate with the instance

  # Add additional configuration for the EC2 instance if required (e.g., user_data, tags, etc.)
}

# Output the provide you information if you need any
output "public_ip" {
  value = aws_instance.custom_ec2_instance.public_ip
}
output "VPC_ID" {
  value = aws_vpc.custom_vpc.id
}
output "Subnet_ID" {
  value = aws_subnet.public_subnet.id
}
