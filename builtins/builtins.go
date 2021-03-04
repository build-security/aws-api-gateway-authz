package builtins

import (
	"github.com/build-security/aws-api-gateway-authz/builtins/geoip"
	"github.com/build-security/aws-api-gateway-authz/builtins/ratelimit"
)

// Register adds custom builtins to OPA.
func Register() {
	geoip.RegisterGeoFromIP()
	ratelimit.RegisterRateLimit()
}
