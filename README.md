# aws-api-gateway-authz

This package provides code used to showcase an example of how Open Policy Agent (OPA) can be used as a Policy Decision Point (PDP) to provide featureful access control.

In our example, we pass [AWS API Gateway](https://aws.amazon.com/api-gateway/) request objects via an [AWS Lambda Authorizer](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html) to the PDP implemented in this package. The PDP makes authz decisions based on the policy we define, using the incoming request as context for the decision. The PDP gives us more fine-grained control than AWS API Gateway's native authz options. For instance, the requests can be authz based on request time of day, on the request IP's geolocation, or be rate-limited in multiple ways.

This package contains:

- An OPA enhancement that adds [two custom builtins functions](./builtins) to create our PDP
- [Policy code](./policy) that defines our access control, by using an AWS API Gateway request object as context for making policy decisions

## Builtins

We've implemented two new builtin functions.
#### - `build.geo_from_ip(ip_address)`

Returns a detailed geolocation object for the given `ip_address` using the [Maxmind GeoLite2 Database](https://dev.maxmind.com/geoip/geoip2/geolite2/).

We can define access control based on geolocation using this builtin.

In the [example](./policy), we use it to check where a request to our AWS API Gateway endpoint is coming from, and allow/deny access based on this information.

#### - `build.rate_limit(key, limit)`

For a predefined `RATE_LIMITER_DURATION`, returns `false` for the the first `limit` times it is called within the duration. Returns `true` if it has been called more than `limit` times within the given duration.

This builtin provides a flexible way to implement rate-limiting on any operation. It needs to be connected to a [Redis](https://redis.io/) server: you can set it up yourself, or use solutions like [AWS ElastiCache](https://aws.amazon.com/elasticache/) (managed Redis).

Because it uses shared memory, this function is safe for use across multiple PDPs. If they are connected to the same Redis server, we can expect the results to be consistent for the given `key` and `limit` across all PDPs.

In the [example](./policy), we use it to rate-limit requests made to our AWS API Gateway endpoint.
## Start up the PDP

After [setting up Redis](https://redis.io/topics/quickstart), you can use our Docker image to run the PDP:

```
docker pull buildsecurity/api-gw-pdp
docker run \
    -e RATE_LIMITER_REDIS_ENDPOINT=<your Redis endpoint> \
    -e RATE_LIMITER_REDIS_PASSWORD=<your Redis password, if you've set one> \
    -e RATE_LIMITER_DURATION=<the duration basis for rate-limiting> \
    -p 8181:8181 \
    --name pdp \
    buildsecurity/api-gw-pdp
```

## Try the builtins using the CLI

After starting the PDP as described above, on a separate terminal, run

```
docker exec -it pdp ./api_gw_pdp run
```

You are now in OPA interactive mode. Try, for example,

```
build.geo_from_ip("8.8.8.8")
```

## Build from scratch

The build downloads Maxmind geolocation assets and packages them into the PDP. To build from scratch, you need to [create a MaxMind account](https://www.maxmind.com/en/geolite2/signup) and [generate a license key](https://www.maxmind.com/en/accounts/current/license-key).

Then from the package root, run
```
MAXMIND_LICENSE_KEY=<your license> make fetch-assets && make build
```

The resulting binary for the PDP works just like the `opa` command:

```
./api_gw_pdp


## Terraform Setup
For your convenience, we have added Terraform scripts for creating the entire set-up of this demonstration on AWS.
For more information, visit the README file in the `aws` directory.
