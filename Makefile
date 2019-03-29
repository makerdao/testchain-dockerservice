APP_NAME ?= testchain_dockerservice
APP_VSN ?= 0.1.0
BUILD ?= `git rev-parse --short HEAD`
TAG ?= latest
ALPINE_VERSION ?= edge
DOCKER_ID_USER ?= makerdao

help:
	@echo "$(APP_NAME):$(APP_VSN)-$(BUILD)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help

build: ## Build elixir application with testchain and WS API
	@docker build \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		-t $(DOCKER_ID_USER)/$(APP_NAME):$(APP_VSN)-$(BUILD) \
		-t $(DOCKER_ID_USER)/$(APP_NAME):$(TAG) .
.PHONY: build

run: ## Run the app in Docker
	@docker run \
		-e NATS_HOST=host.docker.internal \
		-e NATS_PORT=4222 \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--expose 9100-9105 -p 9100-9105:9100-9105 \
		--rm -it $(DOCKER_ID_USER)/$(APP_NAME):$(TAG)
.PHONY: run

dev: ## Run local node with correct values
	@iex --name dockerservice@127.0.0.1 -S mix
.PHONY: dev
