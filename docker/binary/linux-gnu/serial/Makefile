CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr
REGISTRY_IMAGE     ?= $(CI_REGISTRY_IMAGE)/linux-gnu/thread

build: build_openblas
build_openblas:
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):openblas            -f Dockerfile . --target openblas
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):openblas_trilinos12 -f Dockerfile . --target openblas-trilinos12
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):openblas_metis4     -f Dockerfile . --target openblas-metis4

push: push_openblas
push_openblas: build_openblas
	docker push $(REGISTRY_IMAGE):openblas
	docker push $(REGISTRY_IMAGE):openblas_trilinos12
	docker push $(REGISTRY_IMAGE):openblas_metis4
