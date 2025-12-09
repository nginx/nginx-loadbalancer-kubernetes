#!/usr/bin/env bash

set -ex

os="$1"

if [[ -z $CI_COMMIT_SHORT_SHA ]]; then
    CI_COMMIT_SHORT_SHA=$(git rev-parse --short=8 HEAD)
fi
if [[ -z $VERSION ]]; then
    VERSION=$(cat version)
fi

if [ "$os" == "linux" ]; then
    export GOOS=linux
    export GOARCH=amd64
    export CGO_ENABLED=0
fi

mkdir -p "$BUILD_DIR"

pkg_path="./cmd/nginx-loadbalancer-kubernetes"
BUILDPKG="github.com/nginxinc/kubernetes-nginx-ingress/pkg/buildinfo"

ldflags=(
    # Set the value of the string variable in importpath named name to value.
    -X "'$BUILDPKG.semVer=$VERSION'"
    -X "'$BUILDPKG.shortHash=$CI_COMMIT_SHORT_SHA'"
    -s  # Omit the symbol table and debug information.
    -w 	# Omit the DWARF symbol table.
    -extldflags "'-fno-PIC'"
)

go build \
    -v -tags "release osusergo" \
    -ldflags "${ldflags[*]}" \
    -o "${BUILD_DIR}/nginxaas-loadbalancer-kubernetes" \
    "$pkg_path"
