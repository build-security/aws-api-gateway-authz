variable "AWS_REGION" {   
 
    default = "eu-west-2"
}

variable "AWS_ACCESS_KEY"  {
  type        = string
  description = "AWS access key used to create infrastructure"
}


variable "AWS_SECRET_KEY" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"  
}

variable "PRIVATE_KEY_PATH" {
  default = "poc-key-pair"
}

variable "PUBLIC_KEY_PATH" {
  default = "poc-key-pair.pub"
}

variable "EC2_USER" {
  default = "ec2-user"
}

variable "AMI" {
    type = map
    
    default = {
        eu-west-2 = "ami-0b6b51e397faf2316"
        eu-west-3 = "ami-0d9a499b43edd7ae0"
        us-east-1 = "ami-038f1ca1bd58a5790"
        us-east-2 = "ami-07a0844029df33d7d"
    }
}

variable "cidr_block" {
    type = string
    default = "10.1.0.0/16"  
}

variable "CONTROL_PLANE_ADDR" {
  type = string
  default = "https://api.poc.build.security/v1/api/pdp"
}

variable "POLICY_PATH" {
  type = string
  default = "authz"
}
variable "RATE_LIMITER_DURATION" {
  type = string
  default = "30s"
}