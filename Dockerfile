FROM golang:1.15-alpine as builder

ARG REVISION

RUN mkdir -p /podinfo/

WORKDIR /podinfo

COPY cmd cmd
COPY go.mod .
COPY .goreleaser.yml .
COPY go.sum .
COPY pkg pkg
COPY ui ui

RUN go mod download

RUN CGO_ENABLED=0 go build -ldflags "-s -w \
    -X github.com/jukatu/podinfo/pkg/version.REVISION=${REVISION}" \
    -a -o bin/podinfo cmd/podinfo/*

FROM alpine:3.12

ARG BUILD_DATE
ARG VERSION
ARG REVISION

LABEL maintainer="jukatu"

RUN addgroup -S app \
    && adduser -S -g app app \
    && apk --no-cache add \
    ca-certificates curl netcat-openbsd

WORKDIR /home/app

COPY --from=builder /podinfo/bin/podinfo .
COPY --from=builder /podinfo/bin/podcli /usr/local/bin/podcli
COPY ./ui ./ui
RUN chown -R app:app ./

USER app

CMD ["./podinfo"]
