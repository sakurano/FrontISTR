CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr/test

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

build: build-openmpi build-mpich
build-openmpi: build-openmpi_openblas build-openmpi_mkl
build-openmpi_openblas:
	docker build -t $(CI_REGISTRY_IMAGE)/fistr1:openmpi_openblas -f Dockerfile.openmpi_openblas --target fistr1 ../..
build-openmpi_mkl:
	docker build -t $(CI_REGISTRY_IMAGE)/fistr1:openmpi_mkl      -f Dockerfile.openmpi_mkl      --target fistr1 ../..
build-mpich: build-mpich_openblas build-mpich_mkl
build-mpich_openblas:
	docker build -t $(CI_REGISTRY_IMAGE)/fistr1:mpich_openblas   -f Dockerfile.mpich_openblas   --target fistr1 ../..
build-mpich_mkl:
	docker build -t $(CI_REGISTRY_IMAGE)/fistr1:mpich_mkl        -f Dockerfile.mpich_mkl        --target fistr1 ../..

push: login push-openmpi push-mpich
push-openmpi: push-openmpi_openblas push-openmpi_mkl
push-openmpi_openblas: build-openmpi_openblas
	docker push $(CI_REGISTRY_IMAGE)/fistr1:openmpi_openblas
push-openmpi_mkl: build-openmpi_mkl
	docker push $(CI_REGISTRY_IMAGE)/fistr1:openmpi_mkl
push-mpich: push-mpich_openblas push-mpich_mkl
push-mpich_openblas: build-mpich_openblas
	docker push $(CI_REGISTRY_IMAGE)/fistr1:mpich_openblas
push-mpich_mkl: build-mpich_mkl
	docker push $(CI_REGISTRY_IMAGE)/fistr1:mpich_mkl


