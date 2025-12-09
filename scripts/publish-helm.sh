#!/usr/bin/env bash

set -eo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel)

log() {
    printf "\033[0;36m${*}\033[0m\n" >&2
}

publish_helm() {
    pkg="nginxaas-loadbalancer-kubernetes-${version}.tgz"
    log "Packaging Helm chart..."
    helm package --version "${version}" --app-version "${version}" charts/nlk

    log "Pushing Helm chart to registry..."
    helm push "${pkg}" "${repo}"
}

init_ci_vars() {
    if [ -z "$CI_PROJECT_NAME" ]; then
        CI_PROJECT_NAME=nginxaas-loadbalancer-kubernetes
    fi
    if [ -z "$CI_COMMIT_REF_SLUG" ]; then
        CI_COMMIT_REF_SLUG=$(
            git rev-parse --abbrev-ref HEAD | tr "[:upper:]" "[:lower:]" \
                | LANG=en_US.utf8 sed -E -e 's/[^a-zA-Z0-9]/-/g' -e 's/^-+|-+$$//g' \
                | cut -c 1-63
        )
    fi
}

# MAIN
init_ci_vars

# shellcheck source=/dev/null
if [ "$CI" == "true" ]; then
    DEVOPS_DOCKER_URL=$DOCKER_REGISTRY_PROD
else
    DEVOPS_DOCKER_URL=$DOCKER_REGISTRY_DEV
fi
log "Logging into the Helm registry..."
az acr login --name ${DEVOPS_DOCKER_URL%%.*}
repo="oci://${DEVOPS_DOCKER_URL}/nginx-azure-lb/${CI_PROJECT_NAME}/charts/${CI_COMMIT_REF_SLUG}"
# shellcheck source=/dev/null
# shellcheck disable=SC2153
version=$(cat version)

publish_helm
