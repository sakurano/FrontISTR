FROM registry.gitlab.com/frontistr-commons/frontistr/x86_64-linux-gnu/base:thread AS openblas-base
RUN curl -L http://mumps.enseeiht.fr/MUMPS_5.4.0.tar.gz | tar zxv && cd MUMPS_5.4.0 \
 && cp Make.inc/Makefile.inc.generic.SEQ Makefile.inc \
 && make -C src build_mumps_int_def.o build_mumps_int_def \
 && sed \
 -e "s|^CC.*$|CC = gcc|"  \
 -e "s|^FC.*$|FC = gfortran|"  \
 -e "s|^FL.*$|FL = gfortran|" \
 -e "s|^INCPAR.*$|INCPAR = -I${LIB_ROOT}/include|" \
 -e "s|^OPTF.*$|OPTF = -O -fopenmp -DBLR_MT|" \
 -e "s|^OPTC.*$|OPTC = -O -I. -fopenmp|" \
 -e "s|^OPTL.*$|OPTL = -O -fopenmp|" -i Makefile.inc \
 && make RANLIB=ranlib prerequisites libseqneeded -j \
 && make -C src RANLIB=ranlib all -j \
 && cp include/*.h ${LIB_ROOT}/include && cp lib/*.a ${LIB_ROOT}/lib && cp libseq/*.h ${LIB_ROOT}/include && cp libseq/*.a ${LIB_ROOT}/lib \
 && cd .. && rm -fr MUMPS_5.4.0

FROM registry.gitlab.com/frontistr-commons/frontistr/x86_64-linux-gnu/base:thread AS mkl-base
RUN curl -L http://mumps.enseeiht.fr/MUMPS_5.4.0.tar.gz | tar zxv && cd MUMPS_5.4.0 \
 && cp Make.inc/Makefile.inc.generic.SEQ Makefile.inc \
 && make -C src build_mumps_int_def.o build_mumps_int_def \
 && sed \
 -e "s|^CC.*$|CC = gcc|"  \
 -e "s|^FC.*$|FC = gfortran|"  \
 -e "s|^FL.*$|FL = gfortran|" \
 -e "s|^INCPAR.*$|INCPAR = -I${LIB_ROOT}/include|" \
 -e "s|^OPTF.*$|OPTF = -O -fopenmp -DBLR_MT -DGEMMT_AVAILABLE|" \
 -e "s|^OPTC.*$|OPTC = -O -I. -fopenmp|" \
 -e "s|^OPTL.*$|OPTL = -O -fopenmp|" -i Makefile.inc \
 && make RANLIB=ranlib prerequisites libseqneeded -j \
 && make -C src RANLIB=ranlib all -j \
 && cp include/*.h ${LIB_ROOT}/include && cp lib/*.a ${LIB_ROOT}/lib && cp libseq/*.h ${LIB_ROOT}/include && cp libseq/*.a ${LIB_ROOT}/lib \
 && cd .. && rm -fr MUMPS_5.4.0

FROM openblas-base AS openblas
RUN git clone --depth 1 -b trilinos-release-13-0-1 https://github.com/trilinos/Trilinos.git && cd Trilinos \
 && mkdir build; cd build \
 && cmake \
  -DCMAKE_INSTALL_PREFIX=${LIB_ROOT} \
  -DTrilinos_ENABLE_OpenMP=ON \
  -DCMAKE_CXX_FLAGS_NONE_OVERRIDE=-fopenmp \
  -DBUILD_SHARED_LIBS=OFF -DTPL_ENABLE_DLlib=OFF \
  -DTPL_ENABLE_METIS=ON -DTPL_ENABLE_MUMPS=OFF \
  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
  -DTrilinos_ENABLE_TriKota=OFF \
  -DTrilinos_ENABLE_ML=ON \
  -DTrilinos_ENABLE_Zoltan=ON \
  -DTrilinos_ENABLE_OpenMP=ON \
  -DTrilinos_ENABLE_Amesos=ON \
  -DBLAS_LIBRARY_NAMES="openblas" -DLAPACK_LIBRARY_NAMES="openblas" \
  -DTrilinos_ENABLE_Fortran=OFF .. \
 && make -j && make install \
 && cd ../.. && rm -fr Trilinos

FROM openblas-base AS openblas-trilinos12
RUN git clone --depth 1 -b trilinos-release-12-18-1 https://github.com/trilinos/Trilinos.git && cd Trilinos \
 && mkdir build; cd build \
 && cmake \
  -DCMAKE_INSTALL_PREFIX=${LIB_ROOT} \
  -DTrilinos_ENABLE_OpenMP=ON \
  -DCMAKE_CXX_FLAGS_NONE_OVERRIDE=-fopenmp \
  -DBUILD_SHARED_LIBS=OFF -DTPL_ENABLE_DLlib=OFF \
  -DTPL_ENABLE_METIS=ON -DTPL_ENABLE_MUMPS=OFF \
  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
  -DTrilinos_ENABLE_TriKota=OFF \
  -DTrilinos_ENABLE_ML=ON \
  -DTrilinos_ENABLE_Zoltan=ON \
  -DTrilinos_ENABLE_OpenMP=ON \
  -DTrilinos_ENABLE_Amesos=ON \
  -DBLAS_LIBRARY_NAMES="openblas" -DLAPACK_LIBRARY_NAMES="openblas" \
  -DTrilinos_ENABLE_Fortran=OFF .. \
 && make -j && make install \
 && cd ../.. && rm -fr Trilinos

FROM openblas-base AS openblas-metis4
RUN curl -L http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/OLD/metis-4.0.3.tar.gz | tar zxv && cd metis-4.0.3 \
 && sed -e 's/CC = cc/CC = gcc/' -i Makefile.in \
 && make -C Lib -j && cp libmetis.a $LIB_ROOT/lib/ \
 && find Lib -name "*.h"|xargs -i cp {} $LIB_ROOT/include/ \
 && cd .. && rm -fr metis-4.0.3

FROM mkl-base AS mkl
RUN git clone --depth 1 -b trilinos-release-13-0-1 https://github.com/trilinos/Trilinos.git && cd Trilinos \
 && mkdir build; cd build \
 && cmake \
  -DCMAKE_INSTALL_PREFIX=${LIB_ROOT} \
  -DTrilinos_ENABLE_OpenMP=ON \
  -DCMAKE_CXX_FLAGS_NONE_OVERRIDE=-fopenmp \
  -DBUILD_SHARED_LIBS=OFF -DTPL_ENABLE_DLlib=OFF \
  -DTPL_ENABLE_METIS=ON -DTPL_ENABLE_MUMPS=OFF \
  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
  -DTrilinos_ENABLE_TriKota=OFF \
  -DTrilinos_ENABLE_ML=ON \
  -DTrilinos_ENABLE_Zoltan=ON \
  -DTrilinos_ENABLE_OpenMP=ON \
  -DTrilinos_ENABLE_Amesos=ON \
  -DBLAS_LIBRARY_NAMES="mkl_intel_lp64;mkl_gnu_thread;mkl_core" -DLAPACK_LIBRARY_NAMES="mkl_intel_lp64;mkl_gnu_thread;mkl_core" \
  -DTrilinos_ENABLE_Fortran=OFF .. \
 && make -j && make install \
 && cd ../.. && rm -fr Trilinos

FROM mkl-base AS mkl-trilinos12
RUN git clone --depth 1 -b trilinos-release-12-18-1 https://github.com/trilinos/Trilinos.git && cd Trilinos \
 && mkdir build; cd build \
 && cmake \
  -DCMAKE_INSTALL_PREFIX=${LIB_ROOT} \
  -DTrilinos_ENABLE_OpenMP=ON \
  -DCMAKE_CXX_FLAGS_NONE_OVERRIDE=-fopenmp \
  -DBUILD_SHARED_LIBS=OFF -DTPL_ENABLE_DLlib=OFF \
  -DTPL_ENABLE_METIS=ON -DTPL_ENABLE_MUMPS=OFF \
  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
  -DTrilinos_ENABLE_TriKota=OFF \
  -DTrilinos_ENABLE_ML=ON \
  -DTrilinos_ENABLE_Zoltan=ON \
  -DTrilinos_ENABLE_OpenMP=ON \
  -DTrilinos_ENABLE_Amesos=ON \
  -DBLAS_LIBRARY_NAMES="mkl_intel_lp64;mkl_gnu_thread;mkl_core" -DLAPACK_LIBRARY_NAMES="mkl_intel_lp64;mkl_gnu_thread;mkl_core" \
  -DTrilinos_ENABLE_Fortran=OFF .. \
 && make -j && make install \
 && cd ../.. && rm -fr Trilinos

FROM mkl-base AS mkl-metis4
RUN curl -L http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/OLD/metis-4.0.3.tar.gz | tar zxv && cd metis-4.0.3 \
 && sed -e 's/CC = cc/CC = gcc/' -i Makefile.in \
 && make -C Lib -j && cp libmetis.a $LIB_ROOT/lib/ \
 && find Lib -name "*.h"|xargs -i cp {} $LIB_ROOT/include/ \
 && cd .. && rm -fr metis-4.0.3
