include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/petsc-3.8.3)
vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.8.3.tar.gz"
    FILENAME "petsc-3.8.3.tar.gz"
    SHA512 32980ea71c09a59a15e897614b66a0e900ee0d7d65b30343745c452a4bcc8384536f48e846b72250a320aba0251eae0de923ca593185dd1e2ceb4580037d6d5b
)

# Extract the source code with 7Z
# We can not use vcpkg_extract_source_archive here, since the archive
# includes symbolic links that are simply skipped by `cmake -E tar`
vcpkg_find_acquire_program(7Z)
set(EXTRACTION_DIR "${CURRENT_BUILDTREES_DIR}/src")
get_filename_component(ARCHIVE_FILENAME ${ARCHIVE} NAME)
if(NOT EXISTS ${EXTRACTION_DIR}/${ARCHIVE_FILENAME}.extracted)
    message(STATUS "Extracting source ${ARCHIVE}")
    file(MAKE_DIRECTORY ${EXTRACTION_DIR})
    vcpkg_execute_required_process(
        COMMAND ${7Z} e ${ARCHIVE}
        WORKING_DIRECTORY ${EXTRACTION_DIR}
        LOGNAME extract
    )
    vcpkg_execute_required_process(
        COMMAND ${7Z} x "${EXTRACTION_DIR}/petsc-3.8.3.tar" -aos
        WORKING_DIRECTORY ${EXTRACTION_DIR}
        LOGNAME extract2
    )
    file(WRITE ${EXTRACTION_DIR}/${ARCHIVE_FILENAME}.extracted)
endif()
message(STATUS "Extracting done")

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        # SuperLU and Lapack name-mangling is not necessarily the same
        ${CMAKE_CURRENT_LIST_DIR}/fix-assume-superlu-as-lapack.patch
)

# Prepare msys
vcpkg_acquire_msys(MSYS_ROOT)
set(BASH ${MSYS_ROOT}/usr/bin/bash.exe)
set(CYGPATH ${MSYS_ROOT}/usr/bin/cygpath.exe)

macro(to_msys_path PATH OUTPUT_VAR)
    execute_process(
        COMMAND ${CYGPATH} "${PATH}"
        OUTPUT_VARIABLE ${OUTPUT_VAR}
        ERROR_VARIABLE ${OUTPUT_VAR}
        RESULT_VARIABLE error_code
    )
    if(error_code)
        message(FATAL_ERROR "cygpath failed: ${${OUTPUT_VAR}}")
    endif()
    string(REGEX REPLACE "\n" "" ${OUTPUT_VAR} "${${OUTPUT_VAR}}")
endmacro()

to_msys_path("${CURRENT_PACKAGES_DIR}"            MSYS_PACKAGES_DIR)
to_msys_path("${SOURCE_PATH}"                     MSYS_SOURCE_PATH)
to_msys_path("${CURRENT_INSTALLED_DIR}"           VCPKG_INSTALL_DIR)
to_msys_path("${CURRENT_INSTALLED_DIR}/include"   VCPKG_INSTALL_INCLUDE_DIR)
to_msys_path("${CURRENT_INSTALLED_DIR}/lib"       VCPKG_INSTALL_RELEASE_LIB_DIR)
to_msys_path("${CURRENT_INSTALLED_DIR}/debug/lib" VCPKG_INSTALL_DEBUG_LIB_DIR)

# Select fortran compiler
vcpkg_enable_fortran()

if(VCPKG_FORTRAN_COMPILER STREQUAL Intel)
    set(PETSC_FORTRAN_COMPILER "win32fe ifort")
elseif(VCPKG_FORTRAN_COMPILER STREQUAL PGI)
    set(PETSC_FORTRAN_COMPILER "win32fe pgi")
elseif(VCPKG_FORTRAN_COMPILER STREQUAL GNU)
    set(PETSC_FORTRAN_COMPILER "gfortran")
elseif(VCPKG_FORTRAN_COMPILER STREQUAL Flang)
    set(PETSC_FORTRAN_COMPILER "win32fe flang")
else()
    message(FATAL_ERROR "Building PETSc with fortran compiler '${VCPKG_FORTRAN_COMPILER}' is not yet supported.")
endif()

# Generic options
set(OPTIONS
    "${MSYS_SOURCE_PATH}/config/configure.py"
    "--with-cc=win32fe cl"
    "--with-cxx=win32fe cl"
    "--with-fc=${PETSC_FORTRAN_COMPILER}"
    "--ignore-cygwin-link"
    # "--CC_LINKER_FLAGS=-DEBUG -INCREMENTAL:NO -OPT:REF -OPT:ICF"
    # "--CXX_LINKER_FLAGS=-DEBUG -INCREMENTAL:NO -OPT:REF -OPT:ICF"
    "--with-mpi-include=${VCPKG_INSTALL_INCLUDE_DIR}"
    "--with-superlu_dist-include=${VCPKG_INSTALL_INCLUDE_DIR}"
    "--with-metis-include=${VCPKG_INSTALL_INCLUDE_DIR}"
    "--with-parmetis-include=${VCPKG_INSTALL_INCLUDE_DIR}"
    "--with-hypre-include=${VCPKG_INSTALL_INCLUDE_DIR}"
    "--with-scalapack-include=${VCPKG_INSTALL_INCLUDE_DIR}"
    "--with-mumps-include=${VCPKG_INSTALL_INCLUDE_DIR}"
    #"--with-hdf5-include=${VCPKG_INSTALL_INCLUDE_DIR}"
    # --with-pastix=1
    # --with-suitsparse=1
)

# Select CRT flag
if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(RUNTIME_FLAG_NAME "MD")
else()
    set(RUNTIME_FLAG_NAME "MT")
endif()

# Additional Fortran flags
if(VCPKG_FORTRAN_COMPILER STREQUAL Intel)
    if(VCPKG_PLATFORM_TOOLSET STREQUAL "v141")
        file(TO_CMAKE_PATH "$ENV{VCToolsInstallDir}" VCToolsInstallDir)
        string(APPEND ADDITIONAL_CXX_FLAGS "-D__MS_VC_INSTALL_PATH=\"${VCToolsInstallDir}\"")
        string(APPEND ADDITIONAL_C_FLAGS "-D__MS_VC_INSTALL_PATH=\"${VCToolsInstallDir}\"")

        # Because we define __MS_VC_INSTALL_PATH to a path that may includes parenthesis
        # We have to patch a part of the makefile, that will fail with parenthesis in the compile line
        vcpkg_apply_patches(
            SOURCE_PATH ${SOURCE_PATH}
            PATCHES
                ${CMAKE_CURRENT_LIST_DIR}/fix-makefile-print-info.patch
        )
    endif()
    string(APPEND FFLAGS_RELEASE "-${RUNTIME_FLAG_NAME} -names:lowercase -assume:underscore -O3 -DNDEBUG -DWIN32 -D_WINDOWS")
    string(APPEND FFLAGS_DEBUG "-${RUNTIME_FLAG_NAME}d -names:lowercase -assume:underscore -Od -D_DEBUG")
endif()

# Release and Debug options.
# Libraries paths have to be passed explicitly because PETSc is always prefixing library names with 'lib' on windows if no absolute path is passed.
set(OPTIONS_RELEASE
    "--with-debugging=0"
    "--prefix=${MSYS_PACKAGES_DIR}"
    "--CFLAGS=-${RUNTIME_FLAG_NAME} -O2 -Oi -Gy -DNDEBUG -Z7 -DWIN32 -D_WINDOWS -W3 -utf-8 -MP ${ADDITIONAL_C_FLAGS}"
    "--CXXFLAGS=-${RUNTIME_FLAG_NAME} -O2 -Oi -Gy -DNDEBUG -Z7 -DWIN32 -D_WINDOWS -W3 -utf-8 -GR -EHsc -MP ${ADDITIONAL_CXX_FLAGS}"
    "--FFLAGS=${FFLAGS_RELEASE}"
    "--CPPFLAGS=-DNDEBUG -DWIN32 -D_WINDOWS ${ADDITIONAL_C_FLAGS}"
    "--CXXCPPFLAGS=-DNDEBUG -DWIN32 -D_WINDOWS ${ADDITIONAL_C_FLAGS}"
    "--with-mpi-lib=[${VCPKG_INSTALL_RELEASE_LIB_DIR}/msmpi.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/msmpifec.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/msmpifmc.lib]"
    "--with-blas-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/blas.lib"
    "--with-lapack-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/lapack.lib"
    "--with-superlu_dist-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/superlu_dist.lib"
    "--with-metis-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/metis.lib"
    "--with-parmetis-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/parmetis.lib"
    "--with-hypre-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/HYPRE.lib"
    "--with-scalapack-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/scalapack.lib"
    "--with-mumps-lib=[${VCPKG_INSTALL_RELEASE_LIB_DIR}/mumps_common.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/smumps.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/dmumps.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/cmumps.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/zmumps.lib]"
    #"--with-hdf5-lib=[${VCPKG_INSTALL_RELEASE_LIB_DIR}/hdf5.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/hdf5_hl.lib]"
)

set(OPTIONS_DEBUG
    "--with-debugging=1"
    "--prefix=${MSYS_PACKAGES_DIR}/debug"
    "--CFLAGS=-${RUNTIME_FLAG_NAME}d -D_DEBUG -Z7 -Ob0 -Od -RTC1 ${ADDITIONAL_C_FLAGS}"
    "--CXXFLAGS=-${RUNTIME_FLAG_NAME}d -D_DEBUG -Z7 -Ob0 -Od -RTC1 ${ADDITIONAL_CXX_FLAGS}"
    "--FFLAGS=${FFLAGS_DEBUG}"
    "--CPPFLAGS=-D_DEBUG ${ADDITIONAL_C_FLAGS}"
    "--CXXCPPFLAGS=-D_DEBUG ${ADDITIONAL_C_FLAGS}"
    "--with-mpi-lib=[${VCPKG_INSTALL_DEBUG_LIB_DIR}/msmpi.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/msmpifec.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/msmpifmc.lib]"
    "--with-blas-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/blas.lib"
    "--with-lapack-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/lapack.lib"
    "--with-superlu_dist-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/superlu_dist.lib"
    "--with-metis-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/metis.lib"
    "--with-parmetis-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/parmetis.lib"
    "--with-hypre-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/HYPRE.lib"
    "--with-scalapack-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/scalapack.lib"
    "--with-mumps-lib=[${VCPKG_INSTALL_DEBUG_LIB_DIR}/mumps_common.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/smumps.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/dmumps.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/cmumps.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/zmumps.lib]"
    #"--with-hdf5-lib=[${VCPKG_INSTALL_DEBUG_LIB_DIR}/hdf5_D.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/hdf5_hl_D.lib]"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    list(APPEND OPTIONS "--with-shared-libraries=1")
else()
    list(APPEND OPTIONS "--with-shared-libraries=0")
endif()

message(STATUS "Building petsc for Release")
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
vcpkg_execute_required_process(
    COMMAND ${BASH} --noprofile --norc "${CMAKE_CURRENT_LIST_DIR}\\build.sh"
        "${SOURCE_PATH}" # BUILD DIR : In source build
        ${OPTIONS} ${OPTIONS_RELEASE}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME build-${TARGET_TRIPLET}-rel
)

message(STATUS "Building petsc for Debug")
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
vcpkg_execute_required_process(
    COMMAND ${BASH} --noprofile --norc "${CMAKE_CURRENT_LIST_DIR}\\build.sh"
        "${SOURCE_PATH}" # BUILD DIR : In source build
        ${OPTIONS} ${OPTIONS_DEBUG}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
    LOGNAME build-${TARGET_TRIPLET}-dbg
)

# Remove the generated executables
file(RENAME ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/tools)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/bin)

# Move the dlls to the bin folder
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/bin)
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/debug/bin)
file(RENAME ${CURRENT_PACKAGES_DIR}/lib/libpetsc.dll ${CURRENT_PACKAGES_DIR}/bin/libpetsc.dll)
file(RENAME ${CURRENT_PACKAGES_DIR}/lib/libpetsc.pdb ${CURRENT_PACKAGES_DIR}/bin/libpetsc.pdb)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/libpetsc.dll ${CURRENT_PACKAGES_DIR}/debug/bin/libpetsc.dll)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/libpetsc.pdb ${CURRENT_PACKAGES_DIR}/debug/bin/libpetsc.pdb)

# Patch config files
function(fix_petsc_config_file FILEPATH)
    file(READ "${FILEPATH}" FILE_CONTENT)
    string(REPLACE "${MSYS_PACKAGES_DIR}/debug/bin" "${VCPKG_INSTALL_DIR}/tools" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "${MSYS_PACKAGES_DIR}/debug/include" "${VCPKG_INSTALL_DIR}/include" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "${MSYS_PACKAGES_DIR}/bin" "${VCPKG_INSTALL_DIR}/tools" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "${MSYS_PACKAGES_DIR}" "${VCPKG_INSTALL_DIR}" FILE_CONTENT "${FILE_CONTENT}")
    file(WRITE "${FILEPATH}" "${FILE_CONTENT}")
endfunction()

fix_petsc_config_file("${CURRENT_PACKAGES_DIR}/lib/petsc/conf/variables")
fix_petsc_config_file("${CURRENT_PACKAGES_DIR}/lib/petsc/conf/rules")
fix_petsc_config_file("${CURRENT_PACKAGES_DIR}/lib/petsc/conf/petscvariables")

fix_petsc_config_file("${CURRENT_PACKAGES_DIR}/debug/lib/petsc/conf/variables")
fix_petsc_config_file("${CURRENT_PACKAGES_DIR}/debug/lib/petsc/conf/rules")
fix_petsc_config_file("${CURRENT_PACKAGES_DIR}/debug/lib/petsc/conf/petscvariables")

# Remove other debug folders
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/petsc)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/petsc/LICENSE ${CURRENT_PACKAGES_DIR}/share/petsc/copyright)
