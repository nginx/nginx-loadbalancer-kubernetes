#!/usr/bin/env bash

set -eo pipefail

log() {
    printf "\033[0;36m${*}\033[0m\n" >&2
}

docker-image() {

    SRC_REPO="${SRC_REGISTRY}/nginx-azure-lb/nginxaas-loadbalancer-kubernetes/nginxaas-loadbalancer-kubernetes"
    SRC_IMG="${SRC_REPO}:main-${SRC_TAG}"

    DST_REPO="${DST_REGISTRY}/nginx/nginxaas-loadbalancer-kubernetes"
    DST_IMG="${DST_REPO}:${DST_TAG}"

    log "Pulling image from source registry: ${SRC_IMG}"
    docker pull "${SRC_IMG}"

    log "Tagging image for destination registry: ${DST_IMG}"
    docker tag "${SRC_IMG}" "${DST_IMG}"

    log "Pushing image to destination registry: ${DST_IMG}"
    docker push "${DST_IMG}"
}

install_helm() {
  if ! command -v helm >/dev/null; then
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
    chmod 700 get_helm.sh
    ./get_helm.sh
  fi
}

helm-chart() {
    install_helm
    
    SRC_REPO="${SRC_REGISTRY}/nginx-azure-lb/nginxaas-loadbalancer-kubernetes/charts/main/nginxaas-loadbalancer-kubernetes"
    SRC_CHART="oci://${SRC_REPO}"

    DST_REPO="${DST_REGISTRY}/nginxcharts"
    DST_CHART="oci://${DST_REPO}"


    log "Pulling Helm chart from source registry: ${SRC_CHART}"
    helm pull "${SRC_CHART}" --version "${SRC_TAG}"

    log "Pushing Helm chart to destination registry: ${DST_CHART}"
    helm push nginxaas-loadbalancer-kubernetes-${DST_TAG}.tgz "${DST_CHART}"
}


help_text() {
    log "Usage: $(basename $0) <artifact-type>"
}

set_docker_common() {
    if [[ -z "${DOCKERHUB_USERNAME}" ]]; then
        log "DOCKERHUB_USERNAME needs to be set."
        exit 1
    fi

    if [[ -z "${DOCKERHUB_PASSWORD}" ]]; then
        log "DOCKERHUB_PASSWORD needs to be set."
        exit 1
    fi
    SRC_REGISTRY="${DOCKER_REGISTRY_PROD}"
    DST_REGISTRY="docker.io"
    
    log "Logging in to the destination registry..."
    docker login --username "${DOCKERHUB_USERNAME}" --password "${DOCKERHUB_PASSWORD}" "${DST_REGISTRY}"
    
    SRC_TAG=$(echo "${GITHUB_REF_NAME}" | cut -f 2 -d "v")
    DST_TAG="${SRC_TAG}"
}

parse_args() {
    if [[ "$#" -ne 1 ]]; then
        help_text
        exit 0
    fi

    artifact="${1}"
    valid_artifact="(docker-image|helm-chart)"
    valid_artifact_pttn="^${valid_artifact}$"
    if ! [[ "${artifact}" =~ $valid_artifact_pttn ]]; then
        log "Invalid artifact type. Valid artifact types: $valid_artifact"
        help_text
        exit 1
    fi
}

main() {
    if [[ "${CI}" != "true" ]]; then
        log "This script is meant to be run in the CI."
        exit 1
    fi

    pttn="^v[0-9]+\.[0-9]+\.[0-9]+"
    if ! [[ "${GITHUB_REF_NAME}" =~ $pttn ]]; then
        log "\${GITHUB_REF_NAME} needs to be set with valid semver format."
        exit 1
    fi
    
    parse_args "$@"
    ROOT_DIR=$(git rev-parse --show-toplevel)
    set_docker_common
    "$artifact"
}

main "$@"
