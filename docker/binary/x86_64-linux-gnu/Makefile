CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr
SUBDIRS := serial thread process hybrid
ARCH := amd64
export DOCKERARGS:= --add-host github.com:13.114.40.48

.PHONY: clean all build push $(SUBDIRS)
all: build
build: build_serial build_thread
	$(MAKE) subdir MAKECMDGOALS=$@
push: login push_core push_serial push_thread
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
	docker build $(DOCKERARGS) -t $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/runtime:base    -f Dockerfile . --target runtime
	docker build $(DOCKERARGS) -t $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/runtime:openmpi -f Dockerfile . --target runtime-openmpi
	docker build $(DOCKERARGS) -t $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/runtime:mpich   -f Dockerfile . --target runtime-mpich
	docker build $(DOCKERARGS) -t $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/env     -f Dockerfile . --target env
	docker build $(DOCKERARGS) -t $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/core    -f Dockerfile . --target core
build_serial: build_core
	docker build $(DOCKERARGS) -t $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/base:serial -f Dockerfile . --target serial
build_thread: build_core
	docker build $(DOCKERARGS) -t $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/base:thread -f Dockerfile . --target thread

push_core: build_core login
	docker push $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/runtime:base
	docker push $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/runtime:openmpi
	docker push $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/runtime:mpich
	docker push $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/env
	docker push $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/core

push_serial: build_serial
	docker push $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/base:serial
push_thread: build_thread
	docker push $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/base:thread
