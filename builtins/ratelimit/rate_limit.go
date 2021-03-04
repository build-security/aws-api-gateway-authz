package ratelimit

import (
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/build-security/aws-api-gateway-authz/builtins/ratelimit/ratelimiter"

	"github.com/open-policy-agent/opa/ast"
	"github.com/open-policy-agent/opa/rego"
	"github.com/open-policy-agent/opa/topdown/builtins"
	"github.com/open-policy-agent/opa/types"
)

const (
	RateLimitName = "build.rate_limit"
)

var (
	rateLimiter       ratelimiter.RateLimiter
	ratelimitInitlock sync.Once
)

func RegisterRateLimit() {
	rego.RegisterBuiltin2(
		&rego.Function{
			Name:    RateLimitName,
			Decl:    types.NewFunction(types.Args(types.S, types.N), types.B),
			Memoize: false,
		},
		func(bctx rego.BuiltinContext, inpKey, inpMax *ast.Term) (*ast.Term, error) {
			key, err := builtins.StringOperand(inpKey.Value, 1)
			if err != nil {
				return nil, err
			}

			max, err := builtins.NumberOperand(inpMax.Value, 2)
			if err != nil {
				return nil, err
			}

			maxint, ok := max.Int64()
			if !ok {
				return nil, fmt.Errorf("could not convert %v to int64", max)
			}

			limit, err := rateLimit(bctx, string(key), maxint)
			if err != nil {
				return nil, err
			}

			i, err := ast.InterfaceToValue(limit)
			if err != nil {
				return nil, err
			}

			return ast.NewTerm(i), nil
		},
	)
}

func rateLimit(bctx rego.BuiltinContext, key string, max int64) (bool, error) {
	var err error

	ratelimitInitlock.Do(func() {
		err = initRateLimiter(bctx)
	})

	if err != nil {
		return true, fmt.Errorf("error connecting to Redis server: %w", err)
	}

	if rateLimiter == nil {
		return true, fmt.Errorf("the Redis server was not initialized")
	}

	return rateLimiter.Limit(bctx.Context, key, max)
}

const (
	ratelimiterRedisEndpointEnv = "RATE_LIMITER_REDIS_ENDPOINT"
	ratelimiterRedisPasswordEnv = "RATE_LIMITER_REDIS_PASSWORD"
	ratelimiterDurationEnv      = "RATE_LIMITER_DURATION"
)

func initRateLimiter(bctx rego.BuiltinContext) error {
	endpoint := os.Getenv(ratelimiterRedisEndpointEnv)
	password := os.Getenv(ratelimiterRedisPasswordEnv)

	durstr := os.Getenv(ratelimiterDurationEnv)
	duration, err := time.ParseDuration(durstr)
	if err != nil {
		return fmt.Errorf("could not parse duration '%s'", durstr)
	}

	rateLimiter, err = ratelimiter.NewRateLimiter(bctx.Context, &ratelimiter.Config{
		Endpoint: endpoint,
		Password: password,
		Duration: duration,
	})

	return err
}
