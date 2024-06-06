resource "tls_private_key" "app_ssh_key" {
 algorithm = "RSA"
 rsa_bits = 4096
}

resource "aws_key_pair" "app_ssh_key" {
 key_name   = "app_ssh_key"
 public_key = tls_private_key.app_ssh_key.public_key_openssh
}

resource "aws_security_group" "custom_sg" {
  name        = "custom-security-group"
  description = "Allow SSH and other necessary ports"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
  }
}
# Launch the EC2 instance in the public subnet and attach the security group
resource "aws_instance" "custom_ec2_instance" {
  ami           = "ami-0e001c9271cf7f3b9"
  instance_type = "t2.medium"
  tags = {
    Name = "App-Server"
  }
  vpc_security_group_ids = [aws_security_group.custom_sg.id]

  associate_public_ip_address = true  # Assign a public IP to the instance

  key_name = aws_key_pair.app_ssh_key.key_name
  # Add additional configuration for the EC2 instance if required (e.g., user_data, tags, etc.)
  user_data = <<-EOF
                 #!/bin/bash
                 # Install OpenJDK 17 JRE Headless
                 sudo apt install openjdk-17-jre-headless -y
                 # Download Jenkins GPG key
                 sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
                 https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
                 # Add Jenkins repository to package manager sources
                 echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                 https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                 /etc/apt/sources.list.d/jenkins.list > /dev/null
                 # Update package manager repositories
                 sudo apt-get update
                 # Install Jenkins
                 sudo apt-get install jenkins -y

              EOF

}
provisioner "file" {
    source      = "test.sh"
    destination = "/home/ec2-user/test.sh"
    # Connection block
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${path.module}/private_key.pem")
      host        = self.public_ip
 }
}
# Output the provide you information if you need any
output "public_ip" {
  value = aws_instance.custom_ec2_instance.public_ip
}
output "private_key_pem" {
 value     = tls_private_key.app_ssh_key.private_key_pem
 sensitive = true
}
