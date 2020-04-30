#!/bin/bash


# #################################################
# helper functions
# #################################################
function display_help()
{
    echo "rocThust build & installation helper script"
    echo "./install [-h|--help] "
    echo "    [-h|--help] prints this help message"
    echo "    [-i|--install] install after build"
    echo "    [-p|--package] build package"
    echo "    [-r]--relocatable] create a package to support relocatable ROCm"
    #Not implemented yet
    #    echo "    [-d|--dependencies] install build dependencies"
    echo "    [-c|--clients] build library clients too (combines with -i & -d)"
    echo "    [-g|--debug] -DCMAKE_BUILD_TYPE=Debug (default is =Release)"
    echo "    [--hip-clang] build library for amdgpu backend using hip-clang"
}


# #################################################
# global variables
# #################################################
install_package=false
build_package=false
build_clients=false
build_release=true
build_type=Release
build_hip_clang=false
run_tests=false
rocm_path=/opt/rocm
build_relocatable=false

# #################################################
# Parameter parsing
# #################################################

# check if we have a modern version of getopt that can handle whitespace and long parameters
getopt -T
if [[ $? -eq 4 ]]; then
    GETOPT_PARSE=$(getopt --name "${0}" --longoptions help,install,clients,debug,hip-clang,test,package,relocatable --options hicdtprg -- "$@")
else
    echo "Need a new version of getopt"
    exit 1
fi

if [[ $? -ne 0 ]]; then
    echo "getopt invocation failed; could not parse the command line";
    exit 1
fi

eval set -- "${GETOPT_PARSE}"

check_exit_code( )
{
    if (( $1 != 0 )); then
    exit $1
    fi
}

while true; do
    case "${1}" in
        -h|--help)
            display_help
            exit 0
            ;;
        -i|--install)
            install_package=true
            shift ;;
        -p|--package)
            build_package=true
            shift ;;
        -c|--clients)
            build_clients=true
            shift ;;
        -r|--relocatable)
            build_relocatable=true
            shift ;;
        -g|--debug)
            build_type=Debug
            build_release=false
            shift ;;
        -t|--test)
            run_tests=true
            shift ;;
        --hip-clang)
            build_hip_clang=true
            shift ;;
        --) shift ; break ;;
        *)  echo "Unexpected command line parameter received; aborting";
            exit 1
            ;;
    esac
done

if [[ "${build_relocatable}" == true ]]; then
    if ! [ -z ${ROCM_PATH+x} ]; then
        rocm_path=${ROCM_PATH}
    fi
fi

# Create and go to the build directory.
mkdir -p build; cd build

if ($build_release); then
    mkdir -p release; cd release
else
    mkdir -p debug; cd debug
fi

# Set compiler
compiler="hcc"
if [[ "${build_hip_clang}" == true ]]; then
    compiler="hipcc"
fi

cmake_executable="cmake"
if [ -e /etc/redhat-release ] ; then
    cmake_executable="cmake3"
fi

build_test="OFF"
if [[ "${build_clients}" == true ]]; then
    build_test="ON"
fi

if [[ "${build_relocatable}" == true ]]; then
    CXX=$rocm_path/bin/${compiler} ${cmake_executable} \
        -DCMAKE_INSTALL_PREFIX=${rocm_path} \
        -DCMAKE_PREFIX_PATH="${rocm_path} ${rocm_path}/hcc ${rocm_path}/hip" \
        -DCMAKE_MODULE_PATH="${rocm_path}/hip/cmake" \
        -DBUILD_TEST=${build_test} \
         ../../. # or cmake-gui ../.
else
    CXX=$rocm_path/bin/${compiler} ${cmake_executable} -DBUILD_TEST=${build_test} ../../. # or cmake-gui ../.
fi
check_exit_code "$?"

# Build
make -j$(nproc)
check_exit_code "$?"

if ($run_tests); then
# Optionally, run tests if they're enabled.
ctest --output-on-failure
fi

if ($install_package); then
    make install
    check_exit_code "$?"
fi

if ($build_package); then
    make package -j$(nproc)
    check_exit_code "$?"
fi
