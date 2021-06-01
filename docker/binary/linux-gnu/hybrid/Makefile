CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr
REGISTRY_IMAGE     ?= $(CI_REGISTRY_IMAGE)/linux-gnu/thread

build: build_openmpi build_mpich
build_openmpi: build_openmpi_openblas
build_openmpi_openblas:
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):openmpi_openblas            -f Dockerfile.openmpi . --target openblas
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):openmpi_openblas_trilinos12 -f Dockerfile.openmpi . --target openblas-trilinos12
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):openmpi_openblas_metis4     -f Dockerfile.openmpi . --target openblas-metis4
build_mpich: build_mpich_openblas
build_mpich_openblas:
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):mpich_openblas              -f Dockerfile.mpich   . --target openblas
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):mpich_openblas_trilinos12   -f Dockerfile.mpich   . --target openblas-trilinos12
	docker buildx build --platform $(ARCH) -t $(REGISTRY_IMAGE):mpich_openblas_metis4       -f Dockerfile.mpich   . --target openblas-metis4

push: build_openmpi push_mpich
push_openmpi: push_openmpi_openblas
push_openmpi_openblas: build_openmpi_openblas
	docker push $(REGISTRY_IMAGE):openmpi_openblas
	docker push $(REGISTRY_IMAGE):openmpi_openblas_trilinos12
	docker push $(REGISTRY_IMAGE):openmpi_openblas_metis4
push_mpich: push_mpich_openblas
push_mpich_openblas: build_mpich_openblas
	docker push $(REGISTRY_IMAGE):mpich_openblas
	docker push $(REGISTRY_IMAGE):mpich_openblas_trilinos12
	docker push $(REGISTRY_IMAGE):mpich_openblas_metis4
