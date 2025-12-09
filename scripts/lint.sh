#!/usr/bin/env bash

set -x

find . -type f -not -path "./.go/pkg/mod/*" -name \"*.go\" -exec goimports -e -w {} \+;
git diff --exit-code;
golangci-lint run -v ./...;
