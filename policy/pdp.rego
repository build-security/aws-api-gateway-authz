package aws.apigw.pdp

# Set defaults for rules.
default allow_user = "You are not authorized to access this service"
default allow_time = "You cannot access this service in this time period"
default allow_geo = "You cannot access this service from your location"

default stateless_checks_failed = false

default allow_user_rate = "You have exceeded your user request quota for this service"
default allow_group_rate = "You have exceeded your group request quota for this service"

# Based on the architecture, an identity provider will convert
# tokens held by the user to a user identifier. In this example, the
# user is directly accepted as a header.
user := input.headers.user

# Authorization context for this user is fetched from a Data Source,
# for example an AWS DynamoDB table.
user_ctx := data.datasources.internal.users[user]
group_ctx := data.datasources.internal.groups[user_ctx.group]

# Handle basic user check.
allow_user = x {
  user_ctx
  x := true
}

# Handle request time conditions.
epoch_ms = input.requestContext.requestTimeEpoch
request_time := time.clock(epoch_ms*1000000)

allow_time {
  # The starting and ending time, in 24-hour UTC format, is defined for each user.
  start_t := user_ctx.start_time
  end_t := user_ctx.end_time
    
  request_time[0] >= start_t
  request_time[0] < end_t
}

# Handle request geolocation conditions.
ip := input.requestContext.identity.sourceIp

allow_geo {
  geo := build.geo_from_ip(ip)
  
  # Match the IP address geolocation to the allowed geolocations
  # for this user.
  geo.Subdivisions[_].IsoCode == user_ctx.subdivisions[_]
}

stateless_checks = [allow_user, allow_time, allow_geo]

# The following rules affect state, specifically the Redis cache cluster
# used for rate limiting. They should only be evaluated if the previous
# 'stateless' rules have passed successfully.
stateless_checks_failed {
  check := stateless_checks[_]
  not check == true
}

# Handle user rate limiting conditions.
allow_user_rate {
  not stateless_checks_failed

  key := concat("", ["user:", user])
  limit := build.rate_limit(key, user_ctx.rate)
  
  limit == false
}

# Handle group rate limiting conditions.
allow_group_rate {
  not stateless_checks_failed
  
  key := concat("", ["group:", user_ctx.group])
  limit := build.rate_limit(key, group_ctx.rate)
  
  limit == false
}

stateful_checks = [allow_user_rate, allow_group_rate]

all_checks = array.concat(stateless_checks, stateful_checks)

# This rule verifies all required conditions, and also decides
# the message to be shown to the user based on the type of auth denial.
allow {
  passed := [x | x := all_checks[_]; x == true]
  count(passed) == count(all_checks)
}

allow = message {
  failed := [x | x := all_checks[_]; x != true]
  message := failed[0]
}
