package ratelimiter

import (
	"context"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
)

// RateLimiter is the interface that wraps the Limit method.
//
// A RateLimiter implementation helps limit a given operation, by
// keeping track of calls made to Limit.
type RateLimiter interface {
	// Limit decides whether an operation signified by key should
	// be limited or not, based on max operation allowed.
	Limit(ctx context.Context, key string, max int64) (bool, error)
}

// Config describes a Redis based rate limiter.
type Config struct {
	// Redis node connection details.
	Endpoint string // Required.
	Password string

	// What is the time unit for the ratelimiter.
	// For example, time.Second would limit operations on
	// per-second basis. Duration is a required field.
	Duration time.Duration
}

type rateLimiter struct {
	config *Config
	rdb    *redis.Client
}

// NewRateLimiter returns an AWS ElastiCache Redis based implementation of RateLimiter.
func NewRateLimiter(ctx context.Context, conf *Config) (RateLimiter, error) {
	if conf.Endpoint == "" {
		return nil, fmt.Errorf("Endpoint with format addr:port is required to initialize RateLimiter")
	}

	if conf.Duration == 0 {
		return nil, fmt.Errorf("non-zero Duration is required to initialzie RateLimiter")
	}
	return &rateLimiter{
		config: conf,
		rdb: redis.NewClient(&redis.Options{
			Addr:     conf.Endpoint,
			Password: conf.Password,
		}),
	}, nil
}

// TODO(yashtewari): find and fix possible race condition?
func (rl *rateLimiter) Limit(ctx context.Context, key string, max int64) (bool, error) {
	curr, err := rl.rdb.Incr(ctx, key).Result()
	if err != nil {
		return true, err
	}

	if curr > max {
		return true, nil
	} else if curr == 1 {
		if err := rl.rdb.Expire(ctx, key, rl.config.Duration).Err(); err != nil {
			return true, err
		}
	}

	return false, nil
}
