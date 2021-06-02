CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr/multiarch
ARCH ?= arm64,ppc64le

all: build

ifdef CI_COMMIT_TAG
  TAG ?= $(CI_COMMIT_TAG)
else
  ifdef CI_COMMIT_REF_SLUG
    TAG ?= $(CI_COMMIT_REF_SLUG)
    TAG := $(shell echo $(TAG) | sed -e 's/\//__/')
  else
    TAG := _no_branch
  endif
endif

all: build

login:
ifeq ($(CI_BUILD_TOKEN),)
	docker login $(CI_REGISTRY_IMAGE)
else
	docker login -u gitlab-ci-token -p $(CI_BUILD_TOKEN) $(CI_REGISTRY_IMAGE)
endif

build: builder build-openmpi build-mpich
build-openmpi: build-openmpi_openblas
build-openmpi_openblas:
	docker buildx build --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/fistr1:openmpi_openblas -f Dockerfile.openmpi_openblas --target fistr1 ../..
build-mpich: build-mpich_openblas
build-mpich_openblas:
	docker buildx build --builder multiarch --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/fistr1:mpich_openblas -f Dockerfile.mpich_openblas --target fistr1 ../..

push: login builder push-openmpi push-mpich
push-openmpi: push-openmpi_openblas
push-openmpi_openblas: build-openmpi_openblas
	docker buildx build --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/fistr1:openmpi_openblas -f Dockerfile.openmpi_openblas --target fistr1 ../..
push-mpich: push-mpich_openblas
push-mpich_openblas: build-mpich_openblas
	docker buildx build --builder multiarch --push --platform $(ARCH) -t $(CI_REGISTRY_IMAGE)/fistr1:mpich_openblas -f Dockerfile.mpich_openblas --target fistr1 ../..

builder:
	#docker buildx rm --builder multiarch
	-docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	#docker run --rm --privileged multiarch/qemu-user-static --reset
	-docker buildx create --name multiarch --driver docker-container
	-docker buildx inspect --builder multiarch --bootstrap


