FROM debian:buster AS runtime
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install --no-install-recommends -y libopenmpi3 libmpich12 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM runtime AS runtime-openmpi
RUN apt-get update \
 && apt-get install --no-install-recommends -y openmpi-bin libgomp1 \
 && echo >> /etc/openmpi/openmpi-mca-params.conf \
 && echo btl_vader_single_copy_mechanism=none >> /etc/openmpi/openmpi-mca-params.conf \
 && echo btl_openib_allow_ib=true >> /etc/openmpi/openmpi-mca-params.conf \
 && echo btl_openib_warn_default_gid_prefix=0 >> /etc/openmpi/openmpi-mca-params.conf \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM runtime AS runtime-mpich
RUN apt-get update \
 && apt-get install --no-install-recommends -y mpich libgomp1 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM runtime AS env
RUN apt-get update \
 && apt-get -y install --no-install-recommends gcc g++ gfortran libgomp1 \
 && apt-get -y install --no-install-recommends make cmake git zip unzip curl gnupg ca-certificates \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM env AS core
RUN git clone --depth 1 https://github.com/FrontISTR/REVOCAP_Refiner.git && cd REVOCAP_Refiner \
 && make Refiner -j $(nproc) \
 && find lib -type f -name "libRcapRefiner*" -exec cp {} ${LIB_ROOT}/lib/ \; \
 && find . -type f -name "rcapRefiner.h" -exec cp {} ${LIB_ROOT}/include/ \; \
 && cd .. && rm -fr REVOCAP_Refiner

FROM core AS serial
RUN git clone --depth 1 -b v0.3.15 https://github.com/xianyi/OpenBLAS.git && cd OpenBLAS \
 && case $(uname -m) in x86_64) TARGET=NEHALEM;;  aarch64) TARGET=ARMV8;; ppc64le) TARGET=POWER7;; s390x) TARGET=ZARCH_GENERIC;; esac \
 && make USE_OPENMP=0 BINARY=64 DYNAMIC_ARCH=1 NO_SHARED=1 TARGET=$TARGET -j \
 && make PREFIX=${LIB_ROOT} install || true \
 && cd .. && rm -fr OpenBLAS
RUN curl -L http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz | tar zxv && cd metis-5.1.0 \
 && mkdir buildserial && cd buildserial \
 && cmake -DOPENMP=OFF -DGKRAND=ON -DCMAKE_BUILD_TYPE="Release" -DCMAKE_VERBOSE_MAKEFILE=1  -DGKLIB_PATH=../GKlib -DCMAKE_INSTALL_PREFIX="${LIB_ROOT} " .. \
 && make -j && make install \
 && cd ../.. && rm -fr metis-5.1.0

FROM core AS thread
RUN git clone --depth 1 -b v0.3.15 https://github.com/xianyi/OpenBLAS.git && cd OpenBLAS \
 && case $(uname -m) in x86_64) TARGET=NEHALEM;;  aarch64) TARGET=ARMV8;; ppc64le) TARGET=POWER7;; s390x) TARGET=ZARCH_GENERIC;; esac \
 && make USE_OPENMP=1 BINARY=64 DYNAMIC_ARCH=1 NO_SHARED=1 TARGET=$TARGET -j \
 && make PREFIX=${LIB_ROOT} install || true  \
 && cd .. && rm -fr OpenBLAS
RUN curl -L http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz | tar zxv && cd metis-5.1.0 \
 && mkdir buildserial && cd buildserial \
 && cmake -DOPENMP=ON -DGKRAND=ON -DCMAKE_BUILD_TYPE="Release" -DCMAKE_VERBOSE_MAKEFILE=1  -DGKLIB_PATH=../GKlib -DCMAKE_INSTALL_PREFIX="${LIB_ROOT} " .. \
 && make -j && make install \
 && cd ../.. && rm -fr metis-5.1.0
