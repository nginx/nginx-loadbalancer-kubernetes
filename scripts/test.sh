#!/usr/bin/env bash

set -ex

export GO_DATA_RACE=${GO_DATA_RACE:-false}

if [ "$GO_DATA_RACE" == "true" ]; then
    go_flags+=("-race")
fi

outfile="${RESULTS_DIR}/coverage.out"
mkdir -p "$RESULTS_DIR"
go_flags+=("-cover" -coverprofile="$outfile")

set +e
gotestsum --junitfile "${RESULTS_DIR}/report.xml" --format pkgname -- "${go_flags[@]}" ./...
rc=$?
set -e
echo "Total code coverage:"
go tool cover -func="$outfile" | grep 'total:' | tee "${RESULTS_DIR}/anybadge.out"
go tool cover -html="$outfile" -o "${RESULTS_DIR}/coverage.html"
exit $rc
