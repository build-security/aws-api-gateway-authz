resource "aws_internet_gateway" "buildsec-igw" {
    vpc_id = aws_vpc.buildsec-ec2-vpc.id
    tags = {
        Name = "buildsec-igw"
    }
}

resource "aws_route_table" "buildsec-public-crt" {
    vpc_id = aws_vpc.buildsec-ec2-vpc.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.buildsec-igw.id 
    }
    
    tags = {
        Name = "buildsec-public-crt"
    }
}

resource "aws_route_table_association" "buildsec-crta-public-subnet-1"{
    subnet_id = aws_subnet.buildsec-subnet-public-1.id
    route_table_id = aws_route_table.buildsec-public-crt.id
}

resource "aws_security_group" "buildsec-pdp-ec2" {
    vpc_id = aws_vpc.buildsec-ec2-vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8181
        to_port = 8181
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "ssh-allowed"
    }
}

resource "aws_security_group" "buildsec-elasticache" {
    vpc_id = aws_vpc.buildsec-ec2-vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 6379
        to_port = 6379
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
    }
}

resource "aws_security_group" "buildsec-api-gw" {
    vpc_id = aws_vpc.buildsec-ec2-vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

