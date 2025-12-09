#!/usr/bin/env bash

set -eo pipefail

log() {
    printf "\033[0;36m${*}\033[0m\n" >&2
}

package() {
    check_ci
    log "Packaging the CNAB bundle..."
    CMD="cpa buildbundle -d ${BUNDLE_DIR} --telemetryOptOut"
    ${CMD}
}

validate() {
    CMD="cpa verify -d ${BUNDLE_DIR} --telemetryOptOut"
    ${CMD}
    if ! git --no-pager diff --exit-code; then
        log "Bundle validation failed: changes detected after verification."
        exit 1
    fi
}

set_version() {
    VERSION=$(cat version)
}

update_helm_chart() {
    yq -ie '.global.azure.images.nlk.registry = .nlk.image.registry | .global.azure.images.nlk.image = .nlk.image.repository | .global.azure.images.nlk.tag = env(VERSION)' charts/nlk/values.yaml
    yq -ie '.version = env(VERSION) | .appVersion = env(VERSION)' charts/nlk/Chart.yaml
}

update_bundle() {
    yq -ie '.version = env(VERSION)' charts/manifest.yaml
}

check_ci() {
    if [[ "${CI}" != "true" ]]; then
        log "This script with the package arg is meant to be run in the CI."
        exit 1
    fi
}

set_vars() {
    BUNDLE_DIR="${GITHUB_WORKSPACE}/charts/"
}

install_yq() {
    if ! command -v yq &> /dev/null; then
        log "Installing yq..."
        # Download yq binary to user bin
        mkdir -p ~/bin
        curl -sSfL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o ~/bin/yq
        chmod +x ~/bin/yq
        export PATH="$HOME/bin:$PATH"
    fi
}

main() {
    install_yq
    set_vars
    set_version
    update_helm_chart
    update_bundle
    local action="$1"
    case "$action" in
        validate)
        validate
	    ;;
        package)
	    package
	    ;;
	*)
	    log "Action not supported."
	    exit 1
	    ;;
    esac
}

main "$@"
