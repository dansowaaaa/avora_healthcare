
# Step 1: networking foundation (no billable resources).
# VPC, internet gateway, public subnets in two AZs, a route table, and a web security group.

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${local.azs[count.index]}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Public web traffic only. No SSH rule: we will not open port 22.
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Allow inbound HTTP from the internet"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "All outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "app" {
  name        = "avora-app-sg"
  description = "Security group for Avora application servers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "avora-app-sg"
    Project = "avora"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.web.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}
resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "Allow outbound HTTPS traffic"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}


resource "aws_iam_role" "ec2_ssm" {
  name = "avora-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}



resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "ec2" {
  name = "avora-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm.name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_template" "avora" {
  name_prefix   = "avora-server-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -euxo pipefail

dnf install -y nginx
systemctl enable --now nginx

aws s3 cp s3://${aws_s3_bucket.app_assets.bucket}/index.html /usr/share/nginx/html/index.html
aws s3 cp s3://${aws_s3_bucket.app_assets.bucket}/styles.css /usr/share/nginx/html/styles.css
aws s3 cp s3://${aws_s3_bucket.app_assets.bucket}/app.js /usr/share/nginx/html/app.js

chmod 644 /usr/share/nginx/html/*
EOF
  )




  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "avora-server"
      Project = "avora"
    }
  }

  tags = {
    Name    = "avora-launch-template"
    Project = "avora"
  }
}


resource "aws_lb" "avora" {
  name               = "avora-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name    = "avora-alb"
    Project = "avora"
  }
}

resource "aws_lb_target_group" "avora" {
  name     = "avora-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Project = "avora"
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.avora.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.avora.arn
  }
}

resource "aws_autoscaling_group" "avora" {
  name                = "avora-asg"
  min_size            = 2
  desired_capacity    = 2
  max_size            = 3
  vpc_zone_identifier = aws_subnet.public[*].id

  target_group_arns = [
    aws_lb_target_group.avora.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.avora.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "avora-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "avora"
    propagate_at_launch = true
  }

  depends_on = [
    aws_iam_role_policy.ec2_app_assets,
    aws_s3_object.app_index,
    aws_s3_object.app_css,
    aws_s3_object.app_js
  ]
}
