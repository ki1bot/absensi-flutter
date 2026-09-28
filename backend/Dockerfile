FROM golang:1.27.1-alpine3.24

RUN apk add --no-cache \
    ca-certificates \
    git \
    curl

WORKDIR /app

EXPOSE 8080

CMD ["go", "run", "./cmd/api"]