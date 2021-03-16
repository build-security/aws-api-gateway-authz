# AWS-Api-Gateway-Authz Terraform

This Terraform implementation allows to provision a quickstart setup of all AWS resources required for testing purposes and is intended for users who are familiar with Terraform.

The following library will create a new VPC with the following resources: an API gateway, a Lambda function serving as an authorizer , an Elasticache Redis instance and  
an EC2 instance hosting the OPA/PDP docker.

## Instructions

###  Terraform Params:

Update the terraform.tfvars file with the following mandatory parameters:  
1.AWS_SECRET_KEY= "XXXXX"  
2.AWS_ACCESS_KEY= "XXXXXX"  
3.PRIVATE_KEY_PATH = "XXXXXX"  
3.PRIVATE_KEY_PATH = "XXXXXX"  

\* Create a new, unencrypted key, to allow Terraform to establish it on the EC2 instance.  

\* Install the required opa_auth_lambda dependencies by running:
```
cd aws/opa_auth_lambda ; pip3 install -r requirements.txt -t .  
```
\*Please note the optional POLICY_PATH param, In case the policy path was changed from authz to a different value.  


As listed on the variables file, it is also possible to modify the Region & Availability zone(default being eu-west-2).  
You will need to populate the ami map according to your chosen region with the relevant amazon linux x64 architecture ami.

###  Running Terrraform:   
Once all parameters are in place, run the following:
```
Terraform init  
Terraform plan -out  <plan_name>
Terraform apply ./<plan_name>
```
### Start up the PDP:

After the terraform  apply process is finalized successfully, Do the following:  
1. Locate your newly created Redis instance under the Elasticache service on AWS and copy the value from it's primary endpoint field.  

2. Retrieve the EC2 instance public DNS (filter via tag  Name = "EC2_PDP" ) from the AWS console and use your configured key to ssh to it.

Then, on the EC2 instance, run the following command:
```
docker run \
    -e RATE_LIMITER_REDIS_ENDPOINT=<http://your Redis primary endpoint:port> \
    -e RATE_LIMITER_REDIS_PASSWORD=<your Redis password, if you've set one> \
    -e RATE_LIMITER_DURATION=<the duration basis for rate-limiting> \
    -e API_KEY=<the API key provided that was create in the build.security console> \
    -e API_SECRET=<the API secret provided that was create in the build.security console> \
    -e CONTROL_PLANE_ADDR="https://api.poc.build.security/v1/api/pdp" \
    -p 8181:8181 \
    --name pdp \
    buildsecurity/pdp
```
Verify the container is running & that the PDP has retrieved the policy successfully.
