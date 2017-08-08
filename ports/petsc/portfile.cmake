# Common Ambient Variables:
#   VCPKG_ROOT_DIR = <C:\path\to\current\vcpkg>
#   TARGET_TRIPLET is the current triplet (x86-windows, etc)
#   PORT is the current port name (zlib, etc)
#   CURRENT_BUILDTREES_DIR = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR  = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#

include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/petsc-3.7.4)
vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.7.4.tar.gz"
    FILENAME "petsc-3.7.4.tar.gz"
    SHA512 295a2c0da2aee7b68caed1dfd557cdfb7cdc0abc418ef0e36a29b391fc7db30a37c5877274501092beadf1a7b91e01095c9a7f952f7311c836300c6b5d3529c5
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/fix-assume-superlu-as-lapack.patch
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})
file(MAKE_DIRECTORY ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindHYPRE.cmake DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindMETIS.cmake DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindMPI.cmake DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindMUMPS.cmake DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindParMETIS.cmake DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindSuperLU_Dist.cmake DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/PETScBuildInternal.cmake DESTINATION ${SOURCE_PATH}/cmake)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/petscconf.h.in DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/petscconfiginfo.h.in DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/petscfix.h.in DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/petscmachineinfo.h.in DESTINATION ${SOURCE_PATH}/cmake)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/PETSCConfig.cmake.in DESTINATION ${SOURCE_PATH}/cmake)

vcpkg_enable_fortran()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS_DEBUG
        -DPETSC_USE_REAL_DOUBLE=ON
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

# vcpkg_configure_cmake(
#     SOURCE_PATH ${SOURCE_PATH}
#     PREFER_NINJA
#     OPTIONS
#         -DPETSC_USE_COMPLEX=ON
# )

# vcpkg_install_cmake()
# vcpkg_copy_pdbs()

file(READ ${CURRENT_PACKAGES_DIR}/debug/share/petsc/PETSCExports-debug.cmake PETSC_DEBUG_MODULE)
string(REPLACE "\${_IMPORT_PREFIX}" "\${_IMPORT_PREFIX}/debug" PETSC_DEBUG_MODULE "${PETSC_DEBUG_MODULE}")
file(WRITE ${CURRENT_PACKAGES_DIR}/share/petsc/PETSCExports-debug.cmake "${PETSC_DEBUG_MODULE}")

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/include/petsc/finclude/ftn-auto)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/include/petsc/finclude/ftn-custom)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/petsc)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/petsc/LICENSE ${CURRENT_PACKAGES_DIR}/share/petsc/copyright)
