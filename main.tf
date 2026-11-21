# Create an S3 bucket with a globally unique name
resource "aws_s3_bucket" "app_assets" {
  bucket = "terraform-web-app-assets-annur21112026"

  tags = {
    Project   = "terraform-web-app"
    ManagedBy = "terraform"
  }
}

# Look up the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create the VPC that holds all networking resources
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name      = "terraform-web-app-vpc"
    Project   = "terraform-web-app"
    ManagedBy = "terraform"
  }
}

# Create a public subnet inside the VPC
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name    = "terraform-web-app-public"
    Project = "terraform-web-app"
  }
}

# Attach an internet gateway so traffic can reach the public internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "terraform-web-app-igw"
    Project = "terraform-web-app"
  }
}

# Route all outbound traffic through the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "terraform-web-app-public-rt"
    Project = "terraform-web-app"
  }
}

# Link the route table to the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Allow inbound HTTP traffic and all outbound traffic
resource "aws_security_group" "web" {
  name        = "terraform-web-app-web-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "terraform-web-app-web-sg"
    Project = "terraform-web-app"
  }
}

# Launch an EC2 instance that installs and starts nginx on boot
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

    user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl enable nginx
    systemctl start nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head><title>Terraform Web App</title></head>
    <body>
      <h1>Hello from Terraform!</h1>
      <p>Environment: dev</p>
      <p>This server was provisioned entirely with infrastructure as code.</p>
    </body>
    </html>
    HTML
    EOF

  tags = {
    Name      = "terraform-web-app-web"
    Project   = "terraform-web-app"
    Environment = "dev"
    ManagedBy = "terraform"
    
  }
}