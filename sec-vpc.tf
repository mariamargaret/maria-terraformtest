

terraform {
  backend "s3" {
    bucket = "omnex-terraform-state-bucket"
    key    = "sec-vpc/terraform.tfstate"
    region = "us-east-2"
  }
}


# Data source to fetch the state from the prod environment
data "terraform_remote_state" "prod" {
  backend = "s3"

  config = {
    bucket = "omnex-terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_vpc" "sec-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "sec-vpc"
  }
}


resource "aws_internet_gateway" "security-igw" {
  vpc_id = aws_vpc.sec-vpc.id

  tags = {
    Name = "sec-igw"
  }
}

# Create Transit Gateway
resource "aws_ec2_transit_gateway" "sec-tgw" {
  description = "example Transit Gateway"

  tags = {
    Name = "Transit-gateway"
  }
}



# Create Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tgwa" {
  transit_gateway_id = aws_ec2_transit_gateway.sec-tgw.id
  vpc_id             = aws_vpc.sec-vpc.id
  subnet_ids         = [aws_subnet.TGWeni-security.id]

  tags = {
    Name = "-tgw-attachment"
  }
}

# Fetch the existing ENI based on a tag or some other identifier
data "aws_network_interface" "my_eni" {
  filter {
    name   = "subnet-id"
    values = [aws_subnet.TGWeni-security.id]
  }
 #depends_on = [aws_subnet.TGWeni-security]
}

# Create Subnet for FW-MGMT-security
resource "aws_subnet" "FW-MGMT-security" {
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.Subnet_CIDR1

  tags = {
    Name = "FW-MGMT-security"
  }
}


# Create Route Table
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.sec-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.security-igw.id
  }
  
 route {
    cidr_block = aws_vpc.sec-vpc.cidr_block
   # network_interface_id   = data.aws_network_interface.my_eni.id
    gateway_id = "local"
}

  tags = {
    Name = "FW-MGMT-SEC_RT"
        }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.FW-MGMT-security.id
  route_table_id = aws_route_table.rt1.id
}


# Create Subnet for FW-DATA-security
resource "aws_subnet" "FW-DATA-security" {
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.Subnet_CIDR2

  tags = {
    Name = "FW-DATA-security"
  }
}


# Create Route Table
resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.sec-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.security-igw.id
  }

  tags = {
    Name = "FW_DATA-SEC_RT"
        }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.FW-DATA-security.id
  route_table_id = aws_route_table.rt2.id
}




# Create Subnet for NATGW-security
resource "aws_subnet" "NAT-GW-security" {
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.Subnet_CIDR6

  tags = {
    Name = "NAT-GW-security"
  }
}


# Create Route Table
resource "aws_route_table" "rt3" {
  vpc_id = aws_vpc.sec-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.security-igw.id   
  }

  route {
    cidr_block = "10.1.0.0/16"
    vpc_endpoint_id        = aws_vpc_endpoint.sec-gwlb_vpc_endpoint1.id
  }

  route {
    cidr_block = "10.2.0.0/16"
    vpc_endpoint_id        = aws_vpc_endpoint.sec-gwlb_vpc_endpoint1.id
  }
 


  tags = {
    Name = "NATGW-SEC_RT"
        }
}
   

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta3" {
  subnet_id      = aws_subnet.NAT-GW-security.id
  route_table_id = aws_route_table.rt3.id
}



# Allocate Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "NATGW"
        }
}

# Create NAT Gateway
resource "aws_nat_gateway" "sec-nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.NAT-GW-security.id

   tags = {
    Name = "sec-natgw"
  
}
}


# Create Subnet GWLBep-EW-security
resource "aws_subnet" "GWLBep-EW-security" {
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.Subnet_CIDR3
  availability_zone = "us-east-2b"

  tags = {
    Name = "GWLBep-EW-security"
  }
}


# Create Route Table
resource "aws_route_table" "rt4" {
  vpc_id = aws_vpc.sec-vpc.id

  #route {
    #cidr_block = aws_vpc.sec-vpc.cidr_block
   #network_interface_id   = data.aws_network_interface.my_eni.id
    #gateway_id = "local"
#}

 route {
    cidr_block = "10.1.0.0/16"
    network_interface_id   = data.aws_network_interface.my_eni.id
   # gateway_id = "local"
}

 route {
    cidr_block = "10.2.0.0/16"
    network_interface_id   = data.aws_network_interface.my_eni.id
   # gateway_id = "local"
}



  tags = {
    Name = "GWLBe-EW_RT"
        }
}



# Associate Route Table with Subnet
resource "aws_route_table_association" "rta4" {
  subnet_id      = aws_subnet.GWLBep-EW-security.id
  route_table_id = aws_route_table.rt4.id
}

# Create Subnet GWLBep-OUT-security
resource "aws_subnet" "GWLBep-OUT-security" {
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.Subnet_CIDR4
  availability_zone = "us-east-2a"
  tags = {
    Name = "GWLBep-OUT-security"
  }
}

# Create Route Table
resource "aws_route_table" "rt5" {
  vpc_id = aws_vpc.sec-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    #gateway_id = aws_internet_gateway.security-igw.id
    nat_gateway_id         = aws_nat_gateway.sec-nat.id
}
   route {
    cidr_block = "10.1.0.0/16"
    network_interface_id   = data.aws_network_interface.my_eni.id
   # gateway_id = "local"
}

 route {
    cidr_block = "10.2.0.0/16"
    network_interface_id   = data.aws_network_interface.my_eni.id
   # gateway_id = "local"
}


  tags = {
    Name = "GWLBe-OUT_RT"
        }
}


# Associate Route Table with Subnet
resource "aws_route_table_association" "rta5" {
  subnet_id      = aws_subnet.GWLBep-OUT-security.id
  route_table_id = aws_route_table.rt5.id
}


# Create Gateway Load Balancer
resource "aws_lb" "GWLBep-security-lb" {
  name               = "GWLBep-security"
  internal           = false
  load_balancer_type = "gateway"
  subnets            = [aws_subnet.GWLBep-EW-security.id, aws_subnet.GWLBep-OUT-security.id]
#  availability_zone = "us-east-2b" 
  tags = {
    Name = "sec-gwlb"
  }
}


#create targetgroup for gwlb
resource "aws_lb_target_group" "tg" {
  name     = "GWLBep-security-tg"
  target_type = "instance"
  port     = "6081"
  protocol = "GENEVE"
  vpc_id   = aws_vpc.sec-vpc.id

  health_check {
    protocol = "TCP"
    #port     = "6081"
  }

  tags = {
    Name = "GWLBep_security-tg"
  }
}

#Listener for targetgroup
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.GWLBep-security-lb.arn
 # port              = 80
 # protocol          = "GENEVE"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Create an Endpoint Service for the Gateway Load Balancer
resource "aws_vpc_endpoint_service" "sec-gwlb_endpoint_service" {
  acceptance_required = false
  gateway_load_balancer_arns = [aws_lb.GWLBep-security-lb.arn]

  tags = {
    Name = "security-gateway-load-balancer-endpoint-service"
  }
}

# Create a VPC Endpoint for the Endpoint Service
resource "aws_vpc_endpoint" "sec-gwlb_vpc_endpoint" {
  vpc_id            = aws_vpc.sec-vpc.id
  service_name      = aws_vpc_endpoint_service.sec-gwlb_endpoint_service.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.GWLBep-EW-security.id ]

  tags = {
    Name = "sec-vpc-endpoint-EW"
  }
}


# Create a VPC Endpoint for the Endpoint Service
resource "aws_vpc_endpoint" "sec-gwlb_vpc_endpoint1" {
  vpc_id            = aws_vpc.sec-vpc.id
  service_name      = aws_vpc_endpoint_service.sec-gwlb_endpoint_service.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.GWLBep-OUT-security.id ]

  tags = {
    Name = "sec-vpc-endpoint-OUT"
  }
}

# Create Subnet GWLB-security
resource "aws_subnet" "GWLB-security" {
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.Subnet_CIDR8

  tags = {
    Name = "GWLB-security"
  }
}


# Create Route Table
resource "aws_route_table" "rt6" {
  vpc_id = aws_vpc.sec-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.security-igw.id
  }

  tags = {
    Name = "GWLB-RT"
        }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta6" {
  subnet_id      = aws_subnet.GWLB-security.id
  route_table_id = aws_route_table.rt6.id
}



# Create Subnet TGWeni-security
resource "aws_subnet" "TGWeni-security" {
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.Subnet_CIDR5

  tags = {
    Name = "TGWeni-security"
  }
}

# Create Route Table
resource "aws_route_table" "rt7" {
  vpc_id = aws_vpc.sec-vpc.id


   route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.sec-gwlb_vpc_endpoint1.id  
  }

   route {
    cidr_block = "10.1.0.0/16"
    vpc_endpoint_id = aws_vpc_endpoint.sec-gwlb_vpc_endpoint.id
}

 route {
    cidr_block = "10.2.0.0/16"
        vpc_endpoint_id = aws_vpc_endpoint.sec-gwlb_vpc_endpoint.id
}


  tags = {
    Name = "tgweni-security-rt"
  }
}


# Associate Route Table with Subnet
resource "aws_route_table_association" "rta7" {
  subnet_id     = aws_subnet.TGWeni-security.id
  route_table_id = aws_route_table.rt7.id
}

# Create Subnet Bastion-security
resource "aws_subnet" "Bastion-security" {
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.Subnet_CIDR7

  tags = {
    Name = "Bastion-sec"
  }
}


# Create Route Table
resource "aws_route_table" "rt8" {
  vpc_id = aws_vpc.sec-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.security-igw.id
  }
  
  route {
    cidr_block = "10.1.0.0/16"
    network_interface_id   = data.aws_network_interface.my_eni.id
}

route {
    cidr_block = "10.2.0.0/16"
    network_interface_id   = data.aws_network_interface.my_eni.id
}
  tags = {
    Name = "Bastion-RT"
        }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta8" {
  subnet_id     = aws_subnet.Bastion-security.id
  route_table_id = aws_route_table.rt8.id
}
