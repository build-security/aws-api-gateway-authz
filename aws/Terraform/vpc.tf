resource "aws_vpc" "buildsec-ec2-vpc" {
    cidr_block = var.cidr_block
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"
    
    tags = {
        Name = "buildsec-ec2-vpc"
    }
}

resource "aws_subnet" "buildsec-subnet-public-1" {
    vpc_id = aws_vpc.buildsec-ec2-vpc.id
    cidr_block = var.cidr_block
    map_public_ip_on_launch = true//it makes this a public subnet
    availability_zone = "${var.AWS_REGION}-1a"
    
    tags = {
        Name = "buildsec-subnet-public-1"
    }

}