# Copyright 2018 The OPA Authors. All rights reserved.
# Use of this source code is governed by an Apache2
# license that can be found in the LICENSE file.

VERSION := 0.1.0

PACKAGES := $(shell go list ./.../ | grep -v 'vendor')

GO := go
DISABLE_CGO := CGO_ENABLED=0

BIN := api_gw_pdp

REPOSITORY := buildsecurity
IMAGE := $(REPOSITORY)/api-gw-pdp

ASSETS = assets
ASSETS_LIBRARY = $(ASSETS)/statik
MAXMIND_DB_TAR := $(ASSETS)/db.tar.gz
MAXMIND_DB_DIR := $(ASSETS)/GeoLite2-City_*
MAXMIND_DB_FILE_SRC := $(MAXMIND_DB_DIR)/GeoLite2-City.mmdb
MAXMIND_DB_FILE_DST := $(ASSETS)/geolite2-city.mmdb

.PHONY: all build clean check check-fmt check-vet check-lint \
    generate vendor image push test version

######################################################
#
# Development targets
#
######################################################

all: build test check

version:
	@echo $(VERSION)

check-env:
ifndef MAXMIND_LICENSE_KEY
	$(error environment variable MAXMIND_LICENSE_KEY is required)
endif

generate:
	$(GO) generate ./...

update:
	$(GO) get -u

tidy: update
	$(GO) mod tidy

vendor: tidy
	$(GO) mod vendor

fetch-assets: check-env
	mkdir -p $(ASSETS)
	curl --silent --location --request GET \
		'https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${MAXMIND_LICENSE_KEY}&suffix=tar.gz' \
		--output $(MAXMIND_DB_TAR)
	tar xvf $(MAXMIND_DB_TAR) -C $(ASSETS)
	mv $(MAXMIND_DB_FILE_SRC) $(MAXMIND_DB_FILE_DST)
	rm -rf $(MAXMIND_DB_TAR) $(MAXMIND_DB_DIR)
	GO111MODULE=off go get github.com/rakyll/statik
	statik -src=$(ASSETS) -dest=$(ASSETS)

clean-assets:
	rm -rf $(ASSETS)/*

build:
	$(GO) build -o $(BIN) ./main.go

image: check-env
	docker build --build-arg MAXMIND_LICENSE_KEY=${MAXMIND_LICENSE_KEY} -t $(IMAGE):$(VERSION) .

push:
	docker push $(IMAGE):$(VERSION)

test: generate clean-assets fetch-assets
	$(DISABLE_CGO) $(GO) test -v -bench=. $(PACKAGES)

clean: clean-assets
	rm -f .Dockerfile_*
	rm -f opa_*_*
	rm -f *.so

check: check-fmt check-vet check-lint

check-fmt:
	./build/check-fmt.sh

check-vet:
	./build/check-vet.sh

check-lint:
	./build/check-lint.sh
