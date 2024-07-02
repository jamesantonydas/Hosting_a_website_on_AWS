# Configuring AWS Provider

provider "aws" {
  region = "us-east-1"
  # Set environment variables or enter the keys here
  # access_key = "your_access_key_here"
  # secret_key = "your_secret_key_here"
}

# creating a VPC

resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "vpc"
  }
}

# Creating an Internet gateway

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# Creating public subnet

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.az_names[count.index]

  tags = {
    Name = join("-", ["public-subnet", var.az_names[count.index]])
  }
}

# Creating private subnet

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.az_names[count.index]

  tags = {
    Name = join("-", ["private-subnet", var.az_names[count.index]])
  }
}

# Creating public route table

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  
    tags = {
    Name = "public-route-table"
  }
}

# Creating elastic ip

resource "aws_eip" "elastic_ip" {
  count = length(var.private_subnet_cidr)
  domain = "vpc"
  tags = {
    Name = join("-", ["elastic-ip", var.az_names[count.index]])
  }
}

# Creating NAT gateway

resource "aws_nat_gateway" "nat_gateway" {
  count = length(var.public_subnet_cidr)
  connectivity_type = "public"
  allocation_id     = aws_eip.elastic_ip[count.index].id
  subnet_id         = aws_subnet.public_subnets[count.index].id
  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = join("-", ["nat-gateway", var.az_names[count.index]])
  }

  
}

# Creating private route table

resource "aws_route_table" "private_route_table" {
  
  count = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = join("-", ["private_route_table", var.az_names[count.index]])
  }
}

# Route

resource "aws_route" "private-to-nat"{

  count = length(var.private_subnet_cidr)
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.private_route_table[count.index].id
  nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
}

# Creating public route table association

resource "aws_route_table_association" "public_route_association" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# creating private route table association

resource "aws_route_table_association" "private_route_association" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Security Group Resources

resource "aws_security_group" "security_group_lb" {
  name        = "security-group-lb"
  description = "Security Group for load balancer"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP from Internet"
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
    Name = "security-group-load-balancer"
  }
}

# Security group for auto scaling group

resource "aws_security_group" "asg_security_group" {
  name        = "security-group-instance"
  description = "Security Group for EC2 Instance"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.security_group_lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-group-instance"
  }
}

# Launch Template for EC2 instances

resource "aws_launch_template" "launch_template" {
  name          = "ec2-launch-template"
  image_id      = "ami-08a0d1e16fc3f61ea"
  instance_type = "t2.micro"
  key_name = var.key_pair

  network_interfaces {
    device_index    = 0
    security_groups = [aws_security_group.asg_security_group.id]
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
    Name = "ec2-launch-template"
    }
  }

 user_data = filebase64("webserver.sh")
}

# Auto Scaling Group

resource "aws_autoscaling_group" "auto_scaling_group" {
  desired_capacity    = 3
  max_size            = 4
  min_size            = 3
  vpc_zone_identifier = [for i in aws_subnet.private_subnets[*] : i.id]
  target_group_arns   = [aws_lb_target_group.lb_target_group.arn]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }
}

# Load Balancer

resource "aws_lb" "load_balancer" {
  name               = "load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group_lb.id]
  subnets            = [for i in aws_subnet.public_subnets : i.id]
  tags = {
    Name = "Load-balancer"
  }
}

# Load Balancer target group

resource "aws_lb_target_group" "lb_target_group" {
  name     = "lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path    = "/"
    matcher = 200
  }
}

# Load Balancer listener

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

# Output Load balancer url

output "load_balancer_url" {
  description = "link of the webpage"
  value       = "http://${aws_lb.load_balancer.dns_name}"
}
