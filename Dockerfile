FROM golang:1.20.4 as builder
WORKDIR /go/src/github.com/oliver006/redis_exporter/

ADD .  /go/src/github.com/oliver006/redis_exporter/

ARG GOARCH="amd64"
ARG SHA1="[no-sha]"
ARG TAG="[no-tag]"

RUN BUILD_DATE=$(date +%F-%T) CGO_ENABLED=1 GOEXPERIMENT=boringcrypto GOOS=linux GOARCH=$GOARCH go build -o /redis_exporter \
    -ldflags  "-s -w -extldflags \"-static\" -X main.BuildVersion=$TAG -X main.BuildCommitSha=$SHA1 -X main.BuildDate=$BUILD_DATE" .

RUN [ $GOARCH = "amd64" ]  && /redis_exporter -version || ls -la /redis_exporter

#
# scratch release container
#
FROM scratch as scratch

COPY --from=builder /redis_exporter /redis_exporter
COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /etc/nsswitch.conf /etc/nsswitch.conf

# Run as non-root user for secure environments
USER 59000:59000

EXPOSE     9121
ENTRYPOINT [ "/redis_exporter" ]

FROM quay.io/sysdig/sysdig-stig-mini-ubi9:1.2.3 as ubi

COPY --from=builder /redis_exporter /redis_exporter
COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /etc/nsswitch.conf /etc/nsswitch.conf

# Run as non-root user for secure environments
USER 59000:59000

EXPOSE     9121
ENTRYPOINT [ "/redis_exporter" ]
