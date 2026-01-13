# - init general vars
ROOT_DIR = $(shell git rev-parse --show-toplevel)
BUILD_DIR = build
export BUILD_DIR
GO_BUILD_CACHE ?= .go-build
export GO_BUILD_CACHE
RESULTS_DIR = results
export RESULTS_DIR
VERSION = $(shell cat version)
GITHUB_REF_NAME ?= $(shell git rev-parse --abbrev-ref HEAD)
export GITHUB_REF_NAME
CI ?= false
export CI

DOCKER_REPO ?= nginx-azure-lb/nlb-devtools
DOCKER_TAG ?= latest
DEVTOOLS_IMG = $(DOCKER_REGISTRY_PROD)/$(DOCKER_REPO):$(DOCKER_TAG)
CNAB_IMG := mcr.microsoft.com/container-package-app:latest

GITHUB_WORKSPACE ?= $(ROOT_DIR)

.PHONY: .run all helm-lint lint test validate-cnab build-linux build-linux-docker publish publish-helm scan-container-image release-docker-image release-helm-chart release-cnab
.run:
ifeq ($(CI),true)
	$(eval DOCKER_CI_SWITCH_ARGS = -e GOPATH=/tmp/gopath)
else
	$(eval DOCKER_CI_SWITCH_ARGS = -it \
							 -v $(shell go env GOPATH)/pkg:/go/pkg)
endif
	@mkdir -p $(GO_BUILD_CACHE)
	@docker run --rm \
		-v $(ROOT_DIR):$(ROOT_DIR) \
		-v $(ROOT_DIR)/.gitconfig:/.gitconfig \
		-v $(ROOT_DIR)/$(GO_BUILD_CACHE):/.cache/go-build \
		-w $(ROOT_DIR) \
		-e BUILD_DIR=$(BUILD_DIR) \
		-e RESULTS_DIR=$(RESULTS_DIR) \
		-e GITHUB_WORKSPACE=$(GITHUB_WORKSPACE) \
		-e VERSION=$(VERSION) \
		-e HOME=/tmp \
		--user $(shell id -u):$(shell id -g) \
		$(DOCKER_EXTRA_ARGS) \
		$(DOCKER_CI_SWITCH_ARGS) \
		$(or $(img),$(DEVTOOLS_IMG)) $(args)

helm-lint:
	@$(MAKE) .run args="helm lint charts/nlk"

lint:
	@$(MAKE) .run args="$(ROOT_DIR)/scripts/lint.sh"

test:
	@$(MAKE) .run args="$(ROOT_DIR)/scripts/test.sh"

validate-cnab:
	@$(MAKE) .run img="$(CNAB_IMG)" args="$(ROOT_DIR)/scripts/cnab.sh validate"

build-linux:
	@$(MAKE) .run args="$(ROOT_DIR)/scripts/build.sh linux"

build-linux-docker:
	@./scripts/docker.sh build

publish: build-linux build-linux-docker
	@./scripts/docker.sh publish

publish-helm:
	@scripts/publish-helm.sh

scan-container-image:
	@mkdir -p $(RESULTS_DIR)/trivy
	@./scripts/docker.sh pull
	@$(MAKE) .run DOCKER_EXTRA_ARGS=" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--group-add $(shell stat -c '%g' /var/run/docker.sock)" \
		args="trivy image nginxaas-loadbalancer-kubernetes:current"
	@$(MAKE) .run DOCKER_EXTRA_ARGS=" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--group-add $(shell stat -c '%g' /var/run/docker.sock)" \
		args="trivy image --format sarif --output $(RESULTS_DIR)/trivy/trivy-results.sarif \
		nginxaas-loadbalancer-kubernetes:current"

release-docker-image:
	@./scripts/release.sh docker-image

release-helm-chart:
	@./scripts/release.sh helm-chart

release-cnab:
	@$(MAKE) .run img="$(CNAB_IMG)" DOCKER_EXTRA_ARGS=" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--group-add $(shell stat -c '%g' /var/run/docker.sock) \
 		-v $(HOME)/.docker:/root/.docker \
  		-e DOCKER_CONFIG=/root/.docker \
		--user root:root \
		-e HOME=/root \
		-e CI=$(CI)" \
		args="$(ROOT_DIR)/scripts/cnab.sh package"
