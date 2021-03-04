package geoip

import (
	"fmt"
	"testing"
)

const (
	testIP = "8.8.8.8"
)

func TestGeoFromIP(t *testing.T) {
	rec, err := geoFromIP(testIP)
	if err != nil {
		t.Error(err)
	}

	t.Log(rec)

	if len(rec.City.Names) != 0 {
		t.Error(locationObjErr("unexpected city names"))
	}
	if len(rec.Country.Names) == 0 {
		t.Error(locationObjErr("missing country names"))
	}
	if len(rec.Continent.Names) == 0 {
		t.Error(locationObjErr("missing continent names"))
	}
	if rec.Location.TimeZone == "" {
		t.Error(locationObjErr("missing timezone"))
	}
	if rec.Postal.Code != "" {
		t.Error(locationObjErr("unexpected postal code"))
	}
	if len(rec.RegisteredCountry.Names) == 0 {
		t.Error(locationObjErr("missing registered country names"))
	}
	if len(rec.RepresentedCountry.Names) != 0 {
		t.Error(locationObjErr("unexpected represented country names"))
	}
	if len(rec.Subdivisions) != 0 {
		t.Error(locationObjErr("unexpected subdivisions"))
	}
	if rec.Traits.IsAnonymousProxy {
		t.Error(locationObjErr("unexpected anonymous proxy"))
	}
}

func locationObjErr(str string, args ...interface{}) string {
	return fmt.Sprintf("corrupt location object: %s", fmt.Sprintf(str, args...))
}

func BenchmarkGeoFromIP(b *testing.B) {
	b.Run("", func(b *testing.B) {
		_, err := geoFromIP(testIP)
		if err != nil {
			b.Error(err)
		}
	})
}
