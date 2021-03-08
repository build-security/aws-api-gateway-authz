# Build go executable
FROM amd64/golang:1.15.3-alpine3.12 as build-env
RUN apk add --no-cache git make curl

WORKDIR /app
COPY . .
ARG MAXMIND_LICENSE_KEY
RUN make fetch-assets
RUN go mod vendor
RUN GOFLAGS=-mod=vendor make build

# Run executable
FROM alpine:3.12 as run-env
WORKDIR /app

COPY --from=build-env /app/api_gw_pdp .

ENV PDP_LOG_LEVEL=error

CMD ["sh", "-c", "./api_gw_pdp run --server --log-level ${PDP_LOG_LEVEL} --skip-version-check"]