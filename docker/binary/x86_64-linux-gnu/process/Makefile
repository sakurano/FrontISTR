CI_REGISTRY_IMAGE  ?= registry.gitlab.com/frontistr-commons/frontistr
REGISTRY_IMAGE     ?= $(CI_REGISTRY_IMAGE)/x86_64-linux-gnu/process

build: build_openmpi build_mpich
build_openmpi: build_openmpi_openblas build_openmpi_mkl
build_openmpi_openblas:
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):openmpi_openblas            -f Dockerfile.openmpi . --target openblas
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):openmpi_openblas_trilinos12 -f Dockerfile.openmpi . --target openblas-trilinos12
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):openmpi_openblas_metis4     -f Dockerfile.openmpi . --target openblas-metis4
build_openmpi_mkl:
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):openmpi_mkl                 -f Dockerfile.openmpi . --target mkl
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):openmpi_mkl_trilinos12      -f Dockerfile.openmpi . --target mkl-trilinos12
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):openmpi_mkl_metis4          -f Dockerfile.openmpi . --target mkl-metis4
build_mpich: build_mpich_openblas build_mpich_mkl
build_mpich_openblas:
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):mpich_openblas              -f Dockerfile.mpich   . --target openblas
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):mpich_openblas_trilinos12   -f Dockerfile.mpich   . --target openblas-trilinos12
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):mpich_openblas_metis4       -f Dockerfile.mpich   . --target openblas-metis4
build_mpich_mkl:
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):mpich_mkl                   -f Dockerfile.mpich   . --target mkl
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):mpich_mkl_trilinos12        -f Dockerfile.mpich   . --target mkl-trilinos12
	docker build $(DOCKERARGS) -t $(REGISTRY_IMAGE):mpich_mkl_metis4            -f Dockerfile.mpich   . --target mkl-metis4

push: push_openmpi push_mpich
push_openmpi: push_openmpi_openblas push_openmpi_mkl
push_openmpi_openblas: build_openmpi_openblas
	docker push $(REGISTRY_IMAGE):openmpi_openblas
	docker push $(REGISTRY_IMAGE):openmpi_openblas_trilinos12
	docker push $(REGISTRY_IMAGE):openmpi_openblas_metis4
push_openmpi_mkl: build_openmpi_mkl
	docker push $(REGISTRY_IMAGE):openmpi_mkl
	docker push $(REGISTRY_IMAGE):openmpi_mkl_trilinos12
	docker push $(REGISTRY_IMAGE):openmpi_mkl_metis4
push_mpich: push_mpich_openblas push_mpich_mkl
push_mpich_openblas: build_mpich_openblas
	docker push $(REGISTRY_IMAGE):mpich_openblas
	docker push $(REGISTRY_IMAGE):mpich_openblas_trilinos12
	docker push $(REGISTRY_IMAGE):mpich_openblas_metis4
push_mpich_mkl: build_mpich_mkl
	docker push $(REGISTRY_IMAGE):mpich_mkl
	docker push $(REGISTRY_IMAGE):mpich_mkl_trilinos12
	docker push $(REGISTRY_IMAGE):mpich_mkl_metis4
