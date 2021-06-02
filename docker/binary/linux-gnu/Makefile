CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr
SUBDIRS := serial thread process hybrid
#ARCH ?= arm64,ppc64le,s390x
ARCH ?= x86_64,aarch64,ppc64le
export ARCH
export DOCKERARGS:= --add-host github.com:13.114.40.48

.PHONY: clean all build push $(SUBDIRS)
all: build
build: build_serial build_thread
	$(MAKE) subdir MAKECMDGOALS=$@

push: push_serial push_thread
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

build_core: builder
	docker buildx build $(DOCKERARGS) --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:base    -f Dockerfile . --target runtime
	docker buildx build $(DOCKERARGS) --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:openmpi -f Dockerfile . --target runtime-openmpi
	docker buildx build $(DOCKERARGS) --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:mpich   -f Dockerfile . --target runtime-mpich
	docker buildx build $(DOCKERARGS) --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/env     -f Dockerfile . --target env
	docker buildx build $(DOCKERARGS) --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/core    -f Dockerfile . --target core
build_serial: build_core
	docker buildx build $(DOCKERARGS) --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/base:serial -f Dockerfile . --target serial
build_thread: build_core
	docker buildx build $(DOCKERARGS) --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/base:thread -f Dockerfile . --target thread

push_core: builder
	docker buildx build $(DOCKERARGS) --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:base    -f Dockerfile . --target runtime
	docker buildx build $(DOCKERARGS) --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:openmpi -f Dockerfile . --target runtime-openmpi
	docker buildx build $(DOCKERARGS) --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/runtime:mpich   -f Dockerfile . --target runtime-mpich
	docker buildx build $(DOCKERARGS) --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/env     -f Dockerfile . --target env
	docker buildx build $(DOCKERARGS) --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/core    -f Dockerfile . --target core
push_serial: push_core
	docker buildx build $(DOCKERARGS) --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/base:serial -f Dockerfile . --target serial
push_thread: push_core
	docker buildx build $(DOCKERARGS) --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/linux-gnu/base:thread -f Dockerfile . --target thread

builder:
	#docker buildx rm --builder multiarch
	-docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	#docker run --rm --privileged multiarch/qemu-user-static --reset
	-docker buildx create --name multiarch --driver docker-container
	-docker buildx inspect --builder multiarch --bootstrap

