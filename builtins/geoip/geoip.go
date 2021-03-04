package geoip

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
	"sync"

	// Import static files to access database.
	_ "github.com/build-security/aws-api-gateway-authz/assets/statik"

	"github.com/open-policy-agent/opa/ast"
	"github.com/open-policy-agent/opa/rego"
	"github.com/open-policy-agent/opa/topdown/builtins"
	"github.com/open-policy-agent/opa/types"
	"github.com/oschwald/geoip2-golang"
	filesystem "github.com/rakyll/statik/fs"
)

const (
	GeoFromIPName = "build.geo_from_ip"

	databaseFile = "/geolite2-city.mmdb"
)

var (
	memdb    *geoip2.Reader
	initlock sync.Once
)

func RegisterGeoFromIP() {
	rego.RegisterBuiltin1(
		&rego.Function{
			Name:    GeoFromIPName,
			Decl:    types.NewFunction(types.Args(types.S), types.A),
			Memoize: false,
		},
		func(bctx rego.BuiltinContext, inp *ast.Term) (*ast.Term, error) {
			ip, err := builtins.StringOperand(inp.Value, 1)
			if err != nil {
				return nil, err
			}

			geo, err := geoFromIP(string(ip))
			if err != nil {
				return nil, err
			}

			j, err := json.Marshal(geo)
			if err != nil {
				return nil, err
			}

			var x interface{}
			if err := json.Unmarshal(j, &x); err != nil {
				return nil, err
			}

			i, err := ast.InterfaceToValue(x)
			if err != nil {
				return nil, err
			}

			return ast.NewTerm(i), nil
		},
	)
}

func geoFromIP(ip string) (*geoip2.City, error) {
	var err error

	initlock.Do(func() {
		err = initMemdb()
	})

	if err != nil {
		return nil, fmt.Errorf("error initializing MaxMind geolocation database: %w", err)
	}

	if memdb == nil {
		return nil, fmt.Errorf("the MaxMind geolocation database was not initialized")
	}

	return memdb.City(net.ParseIP(ip))
}

func initMemdb() error {
	fs, err := filesystem.New()
	if err != nil {
		return err
	}

	f, err := fs.Open(databaseFile)
	if err != nil {
		return err
	}

	b, err := ioutil.ReadAll(f)
	if err != nil {
		return err
	}

	memdb, err = geoip2.FromBytes(b)
	if err != nil {
		return err
	}

	return nil
}
