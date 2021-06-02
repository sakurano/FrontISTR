CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr
#all: runtime build document
all: runtime build

login:
ifeq ($(CI_BUILD_TOKEN),)
	docker login $(CI_REGISTRY_IMAGE)
else
	docker login -u gitlab-ci-token -p $(CI_BUILD_TOKEN) $(CI_REGISTRY_IMAGE)
endif

runtime:
	docker build -t $(CI_REGISTRY_IMAGE)/runtime:mkl      -f Dockerfile.mkl      . --target runtime
	docker build -t $(CI_REGISTRY_IMAGE)/runtime:openblas -f Dockerfile.openblas . --target runtime
build:
	docker build -t $(CI_REGISTRY_IMAGE)/build:mkl      -f Dockerfile.mkl      . --target build
	docker build -t $(CI_REGISTRY_IMAGE)/build:openblas -f Dockerfile.openblas . --target build
document:
	docker build -t $(CI_REGISTRY_IMAGE)/document:mkl      -f Dockerfile.mkl      . --target document
	docker build -t $(CI_REGISTRY_IMAGE)/document:openblas -f Dockerfile.openblas . --target document
push: login build document
	docker push $(CI_REGISTRY_IMAGE)/build:mkl
	docker push $(CI_REGISTRY_IMAGE)/build:openblas
	docker push $(CI_REGISTRY_IMAGE)/runtime:mkl
	docker push $(CI_REGISTRY_IMAGE)/runtime:openblas
#	docker push $(CI_REGISTRY_IMAGE)/document
#
