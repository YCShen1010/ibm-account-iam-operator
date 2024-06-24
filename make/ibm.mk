DEV_VERSION ?=1.0.0
DEV_REGISTRY ?= quay.io/bedrockinstallerfid

YQ_VERSION ?= v4.44.1

# Change the image to dev when applying deployment manifests
deploy: configure-dev

# Configure the varaiable for the dev build
.PHONY: configure-dev
configure-dev: assgin-tag
	$(eval REGISTRY := $(DEV_REGISTRY))
	$(eval VERSION := $(DEV_VERSION))

# Assign the tag for dev image
.PHONY: assgin-tag
assgin-tag:
ifeq ($(DEV_VERSION),dev)
		$(eval TAG := dev)
endif
	
##@ Development Build
.PHONY: docker-build-dev
docker-build-dev: configure-dev docker-build 
	@echo "DEV_VERSION: $(DEV_VERSION)"
	@echo "VERSION: $(VERSION)"

.PHONY: docker-build-push-dev
docker-build-push-dev: docker-build-dev docker-push

.PHONY: bundle-build-dev
bundle-build-dev: configure-dev bundle-build

.PHONY: bundle-build-push-dev
bundle-build-push-dev: bundle-build-dev bundle-push

.PHONY: catalog-build-dev
catalog-build-dev: configure-dev catalog-build

.PHONY: catalog-build-push-dev
catalog-build-push-dev: catalog-build-dev catalog-push

clean-before-commit:
	cd config/manager && $(KUSTOMIZE) edit set image controller=controller:latest
	cp ./config/manager/manager.yaml ./config/manager/tmp.yaml
	sed -e 's/Always/IfNotPresent/g' ./config/manager/tmp.yaml > ./config/manager/manager.yaml
	rm ./config/manager/tmp.yaml

# yq is a lightweight and portable command-line YAML processor
.PHONY: yq
YQ ?= $(LOCALBIN)/yq
yq:
ifeq (,$(wildcard $(YQ)))
ifeq (, $(shell which yq 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(YQ)) ;\
	OS=$(shell go env GOOS) && ARCH=$(shell go env GOARCH) && \
	curl -sSLo $(YQ) https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/yq_$${OS}_$${ARCH} ;\
	chmod +x $(YQ) ;\
	}
else
YQ = $(shell which yq)
endif
endif

