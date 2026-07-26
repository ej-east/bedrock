# syntax=docker/dockerfile:1.25@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:2e8edce823a48e51858f1fad3ff4cbf6875ce8a3f86b9eecf298bc2050c8652a AS builder

ARG TARGETARCH
ENV GOFIPS140=v1.0.0 \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=${TARGETARCH}

RUN microdnf update -y \
 && microdnf install -y --nodocs golang \
 && go version \
 && microdnf clean all \
 && rm -rf /var/cache/yum /var/cache/dnf

LABEL org.opencontainers.image.base.name="registry.access.redhat.com/ubi9/ubi-minimal" \
      org.opencontainers.image.description="UBI9-minimal Go toolchain for FIPS 140-3 builds (GOFIPS140=v1.0.0, CGO_ENABLED=0)"
