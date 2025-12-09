#!/usr/bin/env bash

set -eo pipefail

ROOT_DIR=$(git rev-parse --show-toplevel)

log() {
    printf "\033[0;36m${*}\033[0m\n" >&2
}

build() {
    log "building image: $IMAGE"
    DOCKER_BUILDKIT=1 docker build --target "$IMAGE" \
        --label VERSION="$version" \
        --label COMMIT="${CI_COMMIT_SHORT_SHA}" \
        --label PROJECT_NAME="${CI_PROJECT_NAME}" \
        --tag "${REPO}:${CI_COMMIT_REF_SLUG}" \
        --tag "${REPO}:${CI_COMMIT_REF_SLUG}-$version" \
        --tag "${REPO}:${CI_COMMIT_SHORT_SHA}" \
        --platform "linux/amd64" \
        -f "${ROOT_DIR}/Dockerfile" .
}

pull() {
    az acr login --name ${DEVOPS_DOCKER_URL%%.*}
    log "pulling image: $IMAGE"
    docker pull "${REPO}:${CI_COMMIT_REF_SLUG}"
    docker tag "${REPO}:${CI_COMMIT_REF_SLUG}" "nginxaas-loadbalancer-kubernetes:current"
}

publish() {
    az acr login --name ${DEVOPS_DOCKER_URL%%.*}
    docker push "$REPO:${CI_COMMIT_REF_SLUG}"
    docker push "$REPO:${CI_COMMIT_REF_SLUG}-$version"
    docker push "$REPO:${CI_COMMIT_SHORT_SHA}"
    if [[ "$CI_COMMIT_REF_SLUG" == "${CI_DEFAULT_BRANCH}" ]]; then
        docker tag "$REPO:${CI_COMMIT_SHORT_SHA}" "$REPO:latest"
        docker tag "$REPO:${CI_COMMIT_SHORT_SHA}" "$REPO:$version"
        docker push "$REPO:latest"
        docker push "$REPO:$version"
      fi
    log "Published the following tags to the container registry:"
    log "  ${REPO}:${CI_COMMIT_REF_SLUG}"
    log "  ${REPO}:${CI_COMMIT_REF_SLUG}-$version"
    log "  ${REPO}:${CI_COMMIT_SHORT_SHA}"
    if [[ "$CI_COMMIT_REF_SLUG" == "${CI_DEFAULT_BRANCH}" ]]; then
        log "  ${REPO}:latest"
        log "  ${REPO}:$version"
    fi
}

init_ci_vars() {
    if [ -z "$CI_COMMIT_SHORT_SHA" ]; then
        CI_COMMIT_SHORT_SHA=$(git rev-parse --short=8 HEAD)
    fi
    CI_PROJECT_NAME=nginxaas-loadbalancer-kubernetes
    if [ -z "$CI_COMMIT_REF_SLUG" ]; then
        CI_COMMIT_REF_SLUG=$(
            git rev-parse --abbrev-ref HEAD | tr "[:upper:]" "[:lower:]" \
                | LANG=en_US.utf8 sed -E -e 's/[^a-zA-Z0-9]/-/g' -e 's/^-+|-+$$//g' \
                | cut -c 1-63
        )
    fi
    if [ -z "$CI_DEFAULT_BRANCH" ]; then
        CI_DEFAULT_BRANCH="main"
    fi
}

print_help () {
    log "Usage:  $(basename "$0") <action>"
}

parse_args() {
    if [[ "$#" -ne 1 ]]; then
        print_help
	exit 0
    fi

    action="$1"

    valid_actions="(build|publish|pull)"
    valid_actions_ptn="^${valid_actions}$"
    if ! [[ "$action" =~ $valid_actions_ptn ]]; then
        log "Invalid action. Valid actions: $valid_actions"
	print_help
	exit 1
    fi
}

# MAIN
parse_args "$@"
init_ci_vars

# shellcheck source=/dev/null
if [ "$CI" == "true" ]; then
    DEVOPS_DOCKER_URL=$DOCKER_REGISTRY_PROD
else
    DEVOPS_DOCKER_URL=$DOCKER_REGISTRY_DEV
fi
IMAGE="nginxaas-loadbalancer-kubernetes"
REPO="${DEVOPS_DOCKER_URL}/nginx-azure-lb/${CI_PROJECT_NAME}/$IMAGE"
# shellcheck source=/dev/null
# shellcheck disable=SC2153
version=$(cat version)

"$action"
