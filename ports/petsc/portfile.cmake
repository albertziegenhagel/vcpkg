include(vcpkg_common_functions)
set(PETSC_VERSION 3.9.3)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/petsc-${PETSC_VERSION})
vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-${PETSC_VERSION}.tar.gz"
    FILENAME "petsc-${PETSC_VERSION}.tar.gz"
    SHA512 d9d8f8f7d596c6a3ef9c242f4f17c1b6c2b5955bde15c0a19108cc46d38d78103022530628237d0c3a1047def07ddaafbf3814db5144fd3e838a30d5c98628c4
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
to_msys_path("${CURRENT_INSTALLED_DIR}/bin"       VCPKG_INSTALL_RELEASE_BIN_DIR)
to_msys_path("${CURRENT_INSTALLED_DIR}/debug/bin" VCPKG_INSTALL_DEBUG_BIN_DIR)

# Extract the source code with `7z`
# We can not use vcpkg_extract_source_archive here, since the archive
# includes symbolic links that are simply skipped by `cmake -E tar`
vcpkg_find_acquire_program(7Z)
set(EXTRACTION_DIR "${CURRENT_BUILDTREES_DIR}/src")
get_filename_component(ARCHIVE_FILENAME ${ARCHIVE} NAME)
if(NOT EXISTS ${EXTRACTION_DIR}/${ARCHIVE_FILENAME}.extracted)
    message(STATUS "Extracting source ${ARCHIVE}")
    file(MAKE_DIRECTORY ${EXTRACTION_DIR})
    vcpkg_execute_required_process(
        COMMAND ${7Z} x ${ARCHIVE} -y
        WORKING_DIRECTORY ${EXTRACTION_DIR}
        LOGNAME extract-1
    )
    vcpkg_execute_required_process(
        COMMAND ${7Z} x petsc-${PETSC_VERSION}.tar -y
        WORKING_DIRECTORY ${EXTRACTION_DIR}
        LOGNAME extract-2
    )
    file(WRITE ${EXTRACTION_DIR}/${ARCHIVE_FILENAME}.extracted)
endif()
message(STATUS "Extracting done")

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/fix-memmove.patch
)

# Select compilers
set(PETSC_C_COMPILER "win32fe cl")
set(PETSC_CXX_COMPILER "win32fe cl")

if("fortran" IN_LIST FEATURES)
    vcpkg_enable_fortran()

    if(VCPKG_FORTRAN_COMPILER STREQUAL Intel)
        set(PETSC_FORTRAN_COMPILER "win32fe ifort")
    elseif(VCPKG_FORTRAN_COMPILER STREQUAL PGI)
        set(PETSC_FORTRAN_COMPILER "win32fe pgi")
    elseif(VCPKG_FORTRAN_COMPILER STREQUAL GNU)
        set(PETSC_C_COMPILER "gcc")
        set(PETSC_CXX_COMPILER "g++")
        set(PETSC_FORTRAN_COMPILER "gfortran")
    elseif(VCPKG_FORTRAN_COMPILER STREQUAL Flang)
        set(PETSC_FORTRAN_COMPILER "flang")
    else()
        message(FATAL_ERROR "Building PETSc with fortran compiler '${VCPKG_FORTRAN_COMPILER}' is not yet supported.")
    endif()
else()
    set(PETSC_FORTRAN_COMPILER "0")
endif()

# Generic options
set(OPTIONS
    "${MSYS_SOURCE_PATH}/config/configure.py"
    "--with-cc=${PETSC_C_COMPILER}"
    "--with-cxx=${PETSC_CXX_COMPILER}"
    "--with-fc=${PETSC_FORTRAN_COMPILER}"
    "--ignore-cygwin-link"
    # "--CC_LINKER_FLAGS=-DEBUG -INCREMENTAL:NO -OPT:REF -OPT:ICF"
    # "--CXX_LINKER_FLAGS=-DEBUG -INCREMENTAL:NO -OPT:REF -OPT:ICF"
)

# Select CRT flag
if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(RUNTIME_FLAG_NAME "MD")
else()
    set(RUNTIME_FLAG_NAME "MT")
endif()

# Additional Fortran flags
if("fortran" IN_LIST FEATURES)
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
    elseif(VCPKG_FORTRAN_COMPILER STREQUAL Flang)
        string(APPEND FFLAGS_RELEASE "-O3 -DNDEBUG -DWIN32 -D_WINDOWS")
        string(APPEND FFLAGS_DEBUG "-Og -D_DEBUG")

        # The PETSc config system appends 'Ws2_32.lib' as a general library to link to but does not handle
        # passing the library to Flang correctly.
        # Since 'Ws2_32.lib' is not required for the Fortran sources anyway, the following patch disables
        # adding that library for Fortran.
        vcpkg_apply_patches(
            SOURCE_PATH ${SOURCE_PATH}
            PATCHES
                ${CMAKE_CURRENT_LIST_DIR}/fix-fortran-flang-libraries.patch
        )
    endif()
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
    "--with-blas-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/blas.lib"
    "--with-lapack-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/lapack.lib"
)

set(OPTIONS_DEBUG
    "--with-debugging=1"
    "--prefix=${MSYS_PACKAGES_DIR}/debug"
    "--CFLAGS=-${RUNTIME_FLAG_NAME}d -D_DEBUG -Z7 -Ob0 -Od -RTC1 ${ADDITIONAL_C_FLAGS}"
    "--CXXFLAGS=-${RUNTIME_FLAG_NAME}d -D_DEBUG -Z7 -Ob0 -Od -RTC1 ${ADDITIONAL_CXX_FLAGS}"
    "--FFLAGS=${FFLAGS_DEBUG}"
    "--CPPFLAGS=-D_DEBUG ${ADDITIONAL_C_FLAGS}"
    "--CXXCPPFLAGS=-D_DEBUG ${ADDITIONAL_C_FLAGS}"
    "--with-blas-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/blas.lib"
    "--with-lapack-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/lapack.lib"
)

list(APPEND OPTIONS "--with-mpi-include=${VCPKG_INSTALL_INCLUDE_DIR}")
if("fortran" IN_LIST FEATURES)
    list(APPEND OPTIONS_RELEASE "--with-mpi-lib=[${VCPKG_INSTALL_RELEASE_LIB_DIR}/msmpi.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/msmpifec.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/msmpifmc.lib]")
    list(APPEND OPTIONS_DEBUG "--with-mpi-lib=[${VCPKG_INSTALL_DEBUG_LIB_DIR}/msmpi.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/msmpifec.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/msmpifmc.lib]")
else()
    list(APPEND OPTIONS_RELEASE "--with-mpi-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/msmpi.lib")
    list(APPEND OPTIONS_DEBUG "--with-mpi-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/msmpi.lib")
endif()

if("scalapack" IN_LIST FEATURES)
    list(APPEND OPTIONS "--with-scalapack-include=${VCPKG_INSTALL_INCLUDE_DIR}")
    list(APPEND OPTIONS_RELEASE "--with-scalapack-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/scalapack.lib")
    list(APPEND OPTIONS_DEBUG "--with-scalapack-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/scalapack.lib")
endif()

if("metis" IN_LIST FEATURES)
    list(APPEND OPTIONS "--with-metis-include=${VCPKG_INSTALL_INCLUDE_DIR}")
    list(APPEND OPTIONS_RELEASE "--with-metis-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/metis.lib")
    list(APPEND OPTIONS_DEBUG "--with-metis-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/metis.lib")
endif()

if("parmetis" IN_LIST FEATURES)
    list(APPEND OPTIONS "--with-parmetis-include=${VCPKG_INSTALL_INCLUDE_DIR}")
    list(APPEND OPTIONS_RELEASE "--with-parmetis-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/parmetis.lib")
    list(APPEND OPTIONS_DEBUG "--with-parmetis-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/parmetis.lib")
endif()

if("hypre" IN_LIST FEATURES)
    list(APPEND OPTIONS "--with-hypre-include=${VCPKG_INSTALL_INCLUDE_DIR}")
    list(APPEND OPTIONS_RELEASE "--with-hypre-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/HYPRE.lib")
    list(APPEND OPTIONS_DEBUG "--with-hypre-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/HYPRE.lib")
endif()

if("superludist" IN_LIST FEATURES)
    list(APPEND OPTIONS "--with-superlu_dist-include=${VCPKG_INSTALL_INCLUDE_DIR}")
    list(APPEND OPTIONS_RELEASE "--with-superlu_dist-lib=${VCPKG_INSTALL_RELEASE_LIB_DIR}/superlu_dist.lib")
    list(APPEND OPTIONS_DEBUG "--with-superlu_dist-lib=${VCPKG_INSTALL_DEBUG_LIB_DIR}/superlu_dist.lib")
endif()

if("mumps" IN_LIST FEATURES)
    list(APPEND OPTIONS "--with-mumps-include=${VCPKG_INSTALL_INCLUDE_DIR}")
    list(APPEND OPTIONS_RELEASE "--with-mumps-lib=[${VCPKG_INSTALL_RELEASE_LIB_DIR}/mumps_common.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/smumps.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/dmumps.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/cmumps.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/zmumps.lib]")
    list(APPEND OPTIONS_DEBUG "--with-mumps-lib=[${VCPKG_INSTALL_DEBUG_LIB_DIR}/mumps_common.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/smumps.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/dmumps.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/cmumps.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/zmumps.lib]")
endif()

if("hdf5" IN_LIST FEATURES)
    list(APPEND OPTIONS "--with-hdf5-include=${VCPKG_INSTALL_INCLUDE_DIR}")
    list(APPEND OPTIONS_RELEASE "--with-hdf5-lib=[${VCPKG_INSTALL_RELEASE_LIB_DIR}/hdf5.lib,${VCPKG_INSTALL_RELEASE_LIB_DIR}/hdf5_hl.lib]")
    list(APPEND OPTIONS_DEBUG "--with-hdf5-lib=[${VCPKG_INSTALL_DEBUG_LIB_DIR}/hdf5_D.lib,${VCPKG_INSTALL_DEBUG_LIB_DIR}/hdf5_hl_D.lib]")

    if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        vcpkg_apply_patches(
            SOURCE_PATH ${SOURCE_PATH}
            PATCHES
                ${CMAKE_CURRENT_LIST_DIR}/use-dynamic-hdf5.patch
        )
    endif()
endif()

if("complex" IN_LIST FEATURES)
    list(APPEND OPTIONS "--with-scalar-type=complex")
    
    if("hypre" IN_LIST FEATURES)
        message(FATAL_ERROR "HYPRE cannot be used when building PETSc with complex scalars. Please disable HYPRE.")
    endif()
endif()

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
        "${VCPKG_INSTALL_RELEASE_BIN_DIR}"
        ${OPTIONS} ${OPTIONS_RELEASE}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME build-${TARGET_TRIPLET}-rel
)

message(STATUS "Building petsc for Debug")
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
vcpkg_execute_required_process(
    COMMAND ${BASH} --noprofile --norc "${CMAKE_CURRENT_LIST_DIR}\\build.sh"
        "${SOURCE_PATH}" # BUILD DIR : In source build
        "${VCPKG_INSTALL_DEBUG_BIN_DIR}"
        ${OPTIONS} ${OPTIONS_DEBUG}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
    LOGNAME build-${TARGET_TRIPLET}-dbg
)

# Remove examples
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/share/petsc/examples)

# Remove the generated executables
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools)
file(RENAME ${CURRENT_PACKAGES_DIR}/lib/petsc/bin ${CURRENT_PACKAGES_DIR}/tools/petsc)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/bin)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/petsc/bin)

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
    string(REPLACE "${MSYS_PACKAGES_DIR}/debug/lib/petsc/bin" "${VCPKG_INSTALL_DIR}/tools" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "${MSYS_PACKAGES_DIR}/debug/include" "${VCPKG_INSTALL_DIR}/include" FILE_CONTENT "${FILE_CONTENT}")
    string(REPLACE "${MSYS_PACKAGES_DIR}/lib/petsc/bin" "${VCPKG_INSTALL_DIR}/tools" FILE_CONTENT "${FILE_CONTENT}")
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
