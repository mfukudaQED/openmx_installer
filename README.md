# Openmx Installer

## Install OpenMX in the Intel OneAPI compiler environment
- [Intel® oneAPI Base Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html?operatingsystem=linux&distributions=aptpackagemanager)
	- For WSL, choose "Linux" and "Offline Installer".
	- Type the commands on a terminal. 
- [Intel® oneAPI HPC Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html?operatingsystem=linux&distributions=aptpackagemanager)

```
bash install_openmx_for_wsl_inteloneapi.sh
```

## Install OpenMX on ISSP supercomputer ohtaka
- Intel oneAPI Classic + OpenMPI + MKL
- used module
  - oneapi_compiler/2023.0.0 oneapi_mkl/2023.0.0 openmpi/4.1.5-oneapi-2023.0.0-classic
```
bash install_openmx_for_ohtaka_inteloneapi_openmpi.sh
```
