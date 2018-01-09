include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/slepc-3.8.2)
vcpkg_download_distfile(ARCHIVE
    URLS "http://slepc.upv.es/download/distrib/slepc-3.8.2.tar.gz"
    FILENAME "slepc-3.8.2.tar.gz"
    SHA512 4d2cbcdd9ecc5e7fca10df85c0248874f379df4c7c5f6158e6896e9d5beced69c8755baf706418cd46dc2a82872a916d244b92b9fef4a7d6e8213d4899729a3e
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/fix-slepc-export.patch
        ${CMAKE_CURRENT_LIST_DIR}/fix-makefile-print-info.patch
        ${CMAKE_CURRENT_LIST_DIR}/vcpkg-install-workarounds.patch
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

vcpkg_enable_fortran()

# Generic options
set(OPTIONS
    "${MSYS_SOURCE_PATH}/config/configure.py"
)
set(OPTIONS_RELEASE
    "--prefix=${MSYS_PACKAGES_DIR}"
)

set(OPTIONS_DEBUG
    "--prefix=${MSYS_PACKAGES_DIR}/debug"
)

message(STATUS "Building slepc for Release")
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
set(ENV{PETSC_DIR} "${VCPKG_INSTALL_DIR}")
vcpkg_execute_required_process(
    COMMAND ${BASH} --noprofile --norc "${CMAKE_CURRENT_LIST_DIR}\\build.sh"
        "${SOURCE_PATH}" # BUILD DIR : In source build
        ${OPTIONS} ${OPTIONS_RELEASE}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME build-${TARGET_TRIPLET}-rel
)

message(STATUS "Building slepc for Debug")
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
set(ENV{PETSC_DIR} "${VCPKG_INSTALL_DIR}/debug")
vcpkg_execute_required_process(
    COMMAND ${BASH} --noprofile --norc "${CMAKE_CURRENT_LIST_DIR}\\build.sh"
        "${SOURCE_PATH}" # BUILD DIR : In source build
        ${OPTIONS} ${OPTIONS_DEBUG}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
    LOGNAME build-${TARGET_TRIPLET}-dbg
)

# Remove the generated executables
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/bin)

# Move the dlls to the bin folder
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/bin)
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/debug/bin)
file(RENAME ${CURRENT_PACKAGES_DIR}/lib/libslepc.dll ${CURRENT_PACKAGES_DIR}/bin/libslepc.dll)
file(RENAME ${CURRENT_PACKAGES_DIR}/lib/libslepc.pdb ${CURRENT_PACKAGES_DIR}/bin/libslepc.pdb)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/libslepc.dll ${CURRENT_PACKAGES_DIR}/debug/bin/libslepc.dll)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/libslepc.pdb ${CURRENT_PACKAGES_DIR}/debug/bin/libslepc.pdb)

# Remove other debug folders
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/slepc)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/slepc/LICENSE ${CURRENT_PACKAGES_DIR}/share/slepc/copyright)

