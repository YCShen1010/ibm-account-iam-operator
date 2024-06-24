REGISTRY ?= quay.io/yuchen_shen

OPERATOR_IMAGE_NAME ?= ibm-account-iam-operator

IMG ?= $(REGISTRY)/$(OPERATOR_IMAGE_NAME):v$(VERSION)

BUNDLE_IMG ?= $(REGISTRY)/$(OPERATOR_IMAGE_NAME)-bundle:v$(VERSION)

CATALOG_IMG ?= $(REGISTRY)/$(OPERATOR_IMAGE_NAME)-catalog:v$(VERSION)

CONTAINER_TOOL ?= docker

VERSION = 1.0.0

YQ_VERSION ?= v4.44.1

# Change the image to dev when applying deployment manifests
deploy: IMG = quay.io/bedrockinstallerfid/ibm-account-iam-operator:dev

# Change the image tag from VERSION to tag when building dev image
.PHONY: docker-build-dev
docker-build-dev: 
	$(eval IMG := $(REGISTRY)/$(OPERATOR_IMAGE_NAME):dev)

.PHONY: bundle-build-dev
bundle-build-dev: 
	$(eval BUNDLE_IMG := $(REGISTRY)/$(OPERATOR_IMAGE_NAME)-bundle:dev)

.PHONY: docker-build-push-dev
docker-build-push-dev: docker-build-dev
	@echo "Building the $(IMG) docker dev image ..."
	$(CONTAINER_TOOL) build -t ${IMG} .
	$(CONTAINER_TOOL) push ${IMG}

.PHONY: bundle-build-push-dev
bundle-build-push-dev: bundle-build-dev
	@echo "Building the $(BUNDLE_IMG) bundle dev image ..."
	$(CONTAINER_TOOL) build -f bundle.Dockerfile -t $(BUNDLE_IMG) .
	$(MAKE) docker-push IMG=$(BUNDLE_IMG)

.PHONY: catalog-build-push-dev
catalog-build-push-dev: opm bundle-build-dev
	$(eval CATALOG_IMG := $(REGISTRY)/$(OPERATOR_IMAGE_NAME)-catalog:dev)
	@echo "Building the $(CATALOG_IMG) catalog dev image ..."
	$(OPM) index add --container-tool docker --mode semver --tag $(CATALOG_IMG) --bundles $(BUNDLE_IMGS) $(FROM_INDEX_OPT)
	$(MAKE) docker-push IMG=$(CATALOG_IMG)

.PHONY: docker-build-push
docker-build-push:
	@echo "Building the $(IMG) docker image ..."
	$(CONTAINER_TOOL) build -t ${IMG} .
	$(CONTAINER_TOOL) push ${IMG}

.PHONY: bundle-build-push
bundle-build-push:
	@echo "Building the $(BUNDLE_IMG) bundle image ..."
	$(CONTAINER_TOOL) build -f bundle.Dockerfile -t $(BUNDLE_IMG) .
	$(MAKE) docker-push IMG=$(BUNDLE_IMG)

.PHONY: catalog-build-push
catalog-build-push: opm
	@echo "Building the $(CATALOG_IMG) catalog image ..."
	$(OPM) index add --container-tool docker --mode semver --tag $(CATALOG_IMG) --bundles $(BUNDLE_IMGS) $(FROM_INDEX_OPT)
	$(MAKE) docker-push IMG=$(CATALOG_IMG)	

clean-before-commit:
	cd config/manager && $(KUSTOMIZE) edit set image controller=controller:latest
	cp ./config/manager/manager.yaml ./config/manager/tmp.yaml
	sed -e 's/Always/IfNotPresent/g' ./config/manager/tmp.yaml > ./config/manager/manager.yaml
	rm ./config/manager/tmp.yaml

.PHONY: yq
YQ ?= $(LOCALBIN)/yq
yq: ## Download operator-sdk locally if necessary.
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

