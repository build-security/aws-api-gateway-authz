resource "aws_instance" "buildsec-pdp" {
    ami = lookup(var.AMI, var.AWS_REGION)
    instance_type = "t2.micro"
    # VPC
    subnet_id = aws_subnet.buildsec-subnet-public-1.id
    # Security Group
    vpc_security_group_ids = [aws_security_group.buildsec-pdp-ec2.id]
    # the Public SSH key
    key_name = aws_key_pair.poc-key-pair.id


    # docker installation

    user_data = <<-EOF
		#! /bin/bash
        sudo yum update -y
		sudo yum install -y docker 
		sudo service docker start
        sudo docker pull buildsecurity/pdp
	EOF

}
// Sends your public key to the instance
resource "aws_key_pair" "poc-key-pair" {
    key_name = "poc-key-pair"
    public_key = file(var.PUBLIC_KEY_PATH)
}