#!/usr/bin/env bash

set -eo pipefail


if [[ "${CI}" != "true" ]]; then
    echo "This script is meant to be run in the CI."
    exit 1
fi

if [[ -n "${GITHUB_HEAD_REF}" ]]; then
    TEST_NLK_CHART_REF="${GITHUB_HEAD_REF}"
else
    TEST_NLK_CHART_REF="${GITHUB_REF_NAME}"
fi

TEST_NLK_CHART_URL="oci://${DOCKER_REGISTRY_PROD}/nginx-azure-lb/nginxaas-loadbalancer-kubernetes/charts/${TEST_NLK_CHART_REF}/nginxaas-loadbalancer-kubernetes"
TEST_NLK_IMG_TAG=$(cat version)
GITLAB_API="${GITLAB_API_URL:-https://gitlab.com/api/v4}"

GITLAB_PIPELINE_ID=$(curl -sS --fail-with-body -X POST \
    --form "ref=main" \
    --form "token=${TRIGGER_TOKEN}" \
    --form "variables[IS_TEST_ONLY]=${IS_TEST_ONLY}" \
    --form "variables[TEST_TYPE]=${TEST_TYPE}" \
    --form "variables[TEST_NLK_CHART_URL]=${TEST_NLK_CHART_URL}" \
    --form "variables[TEST_NLK_IMG_TAG]=${TEST_NLK_IMG_TAG}" \
    --form "variables[TEST_ARGS]=${TEST_ARGS}" \
    "$GITLAB_API/projects/${TRIGGER_PROJECT_ID}/trigger/pipeline" | jq -r .id )

# Poll the triggered pipeline status
deadline=$((SECONDS + 30*60))
while (( SECONDS < deadline )); do
    status="$(
        curl -fsS -H "PRIVATE-TOKEN: $POLL_TOKEN" \
            "$GITLAB_API/projects/${TRIGGER_PROJECT_ID}/pipelines/$GITLAB_PIPELINE_ID" \
        | jq -r .status
    )"
    case "$status" in
        success)
            echo "Test pipeline: $GITLAB_PIPELINE_ID: success";
            exit 0
            ;;
        failed|canceled|skipped)
            echo "Test pipeline: $GITLAB_PIPELINE_ID: $status"
            exit 1
            ;;
        *)
            remaining=$((deadline - SECONDS))
            echo "Test pipeline: $GITLAB_PIPELINE_ID: $status. Waiting 60s (timeout in ${remaining}s)..."
            sleep 60
            ;;
    esac
done

echo "Timed out after 30 minutes waiting for GitLab pipeline $GITLAB_PIPELINE_ID"
exit 1
