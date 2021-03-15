# aws-api-gateway-authz Terraform

This Terraform implementation allows to provision a quickstart setup of all aws resources required for testing purposes.
The following library will create a new vpc with the following resources, an api gateway, a lambda function serving as an authorizer , an elasticache redis instance and
an ec2 instance hosting the opa/pdp docker.

## Instructions

#### - Terraform Params

Update the terraform.tfvars file with the following mandatory parameters:
1.AWS_SECRET_KEY= "XXXXX"
2.AWS_ACCESS_KEY= "XXXXXX"
3.PRIVATE_KEY_PATH = "XXXXXX"
3.PRIVATE_KEY_PATH = "XXXXXX"
* Create a new,unencrypted key, to allow terraform to establish it on the ec2 instance.

please note the optional policy_path param.In case the policy path was changed from authz to a different value.


As listed on the variables file, it is also possible to modify the Region & Availability zone(default being eu-west-2).
You will need to populate the ami map according to your chosen region with the relevant amazon linux x64 architecture ami.

#### - Running Terrraform
Once all parameters are in place, run the following:
Terraform init
Terraform plan
Terraform apply

#### Start up the PDP

After the terraform  apply process is finalized successfully, Do the following:
1.Locate your newly created redis instance under elasticache service on aws and copy the value from it's primary endpoint field.
2.retrieve the ec2 instance public dns(filter via tag  Name = "EC2_PDP" ) from the aws console and use your configured key to ssh to it.
Run the following command:

docker run \
    -e RATE_LIMITER_REDIS_ENDPOINT=<http://your Redis primary endpoint:port> \
    -e RATE_LIMITER_REDIS_PASSWORD=<your Redis password, if you've set one> \
    -e RATE_LIMITER_DURATION=<the duration basis for rate-limiting> \
    -e API_KEY=<your build.security provided api> \
    -e API_SECRET=<your build.security provided secret> \
    -e CONTROL_PLANE_ADDR="https://api.poc.build.security/v1/api/pdp" \
    -p 8181:8181 \
    --name pdp \
    buildsecurity/pdp
```

## Verify the container is running & that the pdp has retrieved the policy successfully.
