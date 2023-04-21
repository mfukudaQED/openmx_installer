#!/bin/bash
#

VERSION=3.9
PATCH=${VERSION}.9
PATCH_URL="https://www.openmx-square.org/bugfixed/21Oct17/patch${PATCH}.tar.gz"

DIR=$PWD
echo "Current directory: $PWD"

echo "Downloading openmx${VERSION}.tar.gz ..."
wget https://www.openmx-square.org/openmx${VERSION}.tar.gz

echo "Extracting openmx${VERSION}.tar.gz ..."
tar zxvf openmx${VERSION}.tar.gz

cd "${DIR}/openmx${VERSION}/source"

echo "Downloading patch${PATCH}.tar.gz ..."
wget ${PATCH_URL}
echo "Extracting patch${PATCH}.tar.gz ..."
tar zxvf patch${PATCH}.tar.gz

echo "Modifying makefile for wsl with intel oneAPI ..."
mv makefile makefile_ori

awk '{
    if($0 ~ /^MKLROOT =/){
         print "MKLROOT = /opt/intel/oneapi/mkl/latest"
    }
    else if($0 ~ /^CC =/){
         print "CC = mpiicc -O3 -xHOST -ip -no-prec-div -qopenmp -I${MKLROOT}/include -I${MKLROOT}/include/fftw"
    }
    else if($0 ~ /^FC =/){
         print "FC = mpiifort -O3 -xHOST -ip -no-prec-div -qopenmp"
    }
    else if($0 ~ /^LIB=/){
         print "LIB= -L${MKLROOT}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -lifcore -lmkl_blacs_intelmpi_lp64 -liomp5 -lpthread -lm -ldl"
    }
    else{
        print $0
    }
}' makefile_ori > makefile 

echo ""
echo "List of compilers and libraries:"
echo $MKLROOT
which mpiicc
which mpiifort
echo ""

echo "Compiling OpenMX ..."
make all
make install
echo "Finished."
echo ""


cd "${DIR}"

echo "Binary of OpenMX is ${DIR}/openmx${VERSION}/source/openmx"
echo "Runtest can be performed by the following command:"
echo "cd \"${DIR}/openmx${VERSION}/work\""
echo "mpirun -np 4 ./openmx -runtest -nt 1"

