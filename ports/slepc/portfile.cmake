include(vcpkg_common_functions)
set(SLEPC_VERSION 3.9.2)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/slepc-${SLEPC_VERSION})
vcpkg_download_distfile(ARCHIVE
    URLS "http://slepc.upv.es/download/distrib/slepc-${SLEPC_VERSION}.tar.gz"
    FILENAME "slepc-${SLEPC_VERSION}.tar.gz"
    SHA512 ef06c478ab38850101b9e18ffd6bf1feff58c93634cef7a3814f7ee4c1c538ee2075c2553fbd984219a98451cf52f2035ee4d2f713397cb54338bacf62e4972d
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
to_msys_path("${CURRENT_INSTALLED_DIR}/bin"       VCPKG_INSTALL_RELEASE_BIN_DIR)
to_msys_path("${CURRENT_INSTALLED_DIR}/debug/bin" VCPKG_INSTALL_DEBUG_BIN_DIR)

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
        "${VCPKG_INSTALL_RELEASE_BIN_DIR}"
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
        "${VCPKG_INSTALL_DEBUG_BIN_DIR}"
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

