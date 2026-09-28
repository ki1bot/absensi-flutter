FROM golang:1.27.1-alpine3.24

RUN apk add --no-cache \
    ca-certificates \
    git \
    curl \
    tzdata

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go test ./...

RUN go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /usr/local/bin/absensi-api \
    ./cmd/api

EXPOSE 8080

CMD ["/usr/local/bin/absensi-api"]