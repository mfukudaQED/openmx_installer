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
tar zxvf openmx${VERSION}.tar.gz 1>/dev/null

cd ${DIR}/openmx${VERSION}/source

echo "Downloading patch${PATCH}.tar.gz ..."
wget ${PATCH_URL}
echo "Extracting patch${PATCH}.tar.gz ..."
tar zxvf patch${PATCH}.tar.gz 1>/dev/null

echo ""
echo "Modifying makefile for ohtaka with intel oneAPI + OpenMPI + MKL ..."
mv makefile makefile_ori

awk '{
    if($0 ~ /^MKLROOT =/){
         print ""
    }
    else if($0 ~ /^CC =/){
         print "CC = mpicc -O3 -march=core-avx2 -ip -no-prec-div -qopenmp -I${MKLROOT}/include/fftw -parallel -par-schedule-auto -static-intel -qopenmp-link=static -qopt-malloc-options=3 -qopt-report"
#
    }
    else if($0 ~ /^FC =/){
         print "FC = mpifort -O3 -march=core-avx2 -ip -no-prec-div -qopenmp -parallel -par-schedule-auto -static-intel -qopenmp-link=static -qopt-malloc-options=3 -qopt-report"
    }
    else if($0 ~ /^LIB=/){
         print "LIB= -L${MKLROOT}/lib/intel64 -mkl=parallel -lmkl_scalapack_lp64 -lmkl_blacs_openmpi_lp64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread -lm -lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi  -lifcoremt"
    }
    else{
        print $0
    }
}' makefile_ori > makefile 


cd ${DIR}

### make.sbatch ###
FILEOUT1="${DIR}/openmx${VERSION}/source/make.sbatch"

cat << 'EOF' > ${FILEOUT1}
#!/bin/bash
#SBATCH -J test
#SBATCH -p i8cpu
#SBATCH -N 1
#SBATCH -t 0:30:0
#SBATCH --exclusive

cd ${SLURM_SUBMIT_DIR}

ulimit -s unlimited

module purge
module load oneapi_compiler/2023.0.0 oneapi_mkl/2023.0.0 openmpi/4.1.5-oneapi-2023.0.0-classic

echo "List of compilers and libraries:"
echo $MKLROOT
which mpiicc
which mpiifort

make -j 32 > make.log
make -j 32 >> make.log
make all >> make.log
make install
EOF
### end make.sbatch ###
### end make.sbatch ###

cat << EOF

To compile OpenMX, use the following command:
cd ${DIR}/openmx${VERSION}/source
sbatch make.sbatch

EOF

### runtest.sbatch ###
FILEOUT2="${DIR}/openmx${VERSION}/work/runtest.sbatch"

cat << 'EOF' > ${FILEOUT2}
#!/bin/bash
#SBATCH -J test
#SBATCH -p i8cpu
#SBATCH -N 1
#SBATCH -n 32
#SBATCH -c 4
#SBATCH -t 0:30:0
#SBATCH --exclusive

cd ${SLURM_SUBMIT_DIR}

ulimit -s unlimited

module purge
module load oneapi_compiler/2023.0.0 oneapi_mkl/2023.0.0 openmpi/4.1.5-oneapi-2023.0.0-classic
export UCX_TLS='self,sm,ud'

NUM_NODES=${SLURM_JOB_NUM_NODES}
NUM_PROCS=${SLURM_NPROCS}
NUM_THREADS=${SLURM_CPUS_PER_TASK}
export OMP_NUM_THREADS=${NUM_THREADS}

LOGFILE="runtest_${SLURM_JOBID}.log"
EOF

echo "EXEFILE=\"${DIR}/openmx${VERSION}/work/openmx\"" >> ${FILEOUT2}

cat << 'EOF' >> ${FILEOUT2}
date &> ${LOGFILE}
cat << END &>> ${LOGFILE}
---------------------------
NUM_NODES = ${NUM_NODES}
NUM_PROCS = ${NUM_PROCS}
NUM_THREADS = ${NUM_THREADS}
---------------------------
END

srun --exclusive ${EXEFILE} -runtest -nt ${OMP_NUM_THREADS} &>> ${LOGFILE}
date &>> ${LOGFILE}
EOF
### end runtest.sbatch ###


cat << EOF
Binary of OpenMX is ${DIR}/openmx${VERSION}/source/openmx
Runtest can be performed by the following command:

cd ${DIR}/openmx${VERSION}/work
sbatch runtest.sbatch

Check runtest.result file to confirm whether the installation have succeeded.
EOF


