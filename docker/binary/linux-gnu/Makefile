CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr
SUBDIRS := serial thread process hybrid
ARCH := aarch64,ppc64le,s390x
export ARCH

.PHONY: clean all build push $(SUBDIRS)

all: build

build: build_serial build_thread
	$(MAKE) subdir MAKECMDGOALS=$@
push: login push_serial push_thread
	$(MAKE) subdir MAKECMDGOALS=$@

subdir: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

login:
ifeq ($(CI_BUILD_TOKEN),)
	docker login $(CI_REGISTRY_IMAGE)
else
	docker login -u gitlab-ci-token -p $(CI_BUILD_TOKEN) $(CI_REGISTRY_IMAGE)
endif

build_core:
	docker buildx build --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:base    -f Dockerfile . --target runtime
	docker buildx build --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:openmpi -f Dockerfile . --target runtime-openmpi
	docker buildx build --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:mpich   -f Dockerfile . --target runtime-mpich
	docker buildx build --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/env     -f Dockerfile . --target env
	docker buildx build --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/core    -f Dockerfile . --target core
build_serial: build_core
	docker buildx build --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/base:serial -f Dockerfile . --target serial
build_thread: build_core
	docker buildx build --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/base:thread -f Dockerfile . --target thread

push_core: build_core login
	docker push $(CI_REGISTRY_IMAGE)/linux-gnu/runtime
	docker push $(CI_REGISTRY_IMAGE)/linux-gnu/env
	docker push $(CI_REGISTRY_IMAGE)/linux-gnu/core

push_serial: build_serial
	docker push $(CI_REGISTRY_IMAGE)/linux-gnu/base:serial
push_thread: build_thread
	docker push $(CI_REGISTRY_IMAGE)/linux-gnu/base:thread
