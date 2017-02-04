include(vcpkg_common_functions)
set(LAPACK_VERSION "3.7.0")
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/lapack-${LAPACK_VERSION})
vcpkg_download_distfile(ARCHIVE
    URLS "https://github.com/Reference-LAPACK/lapack/archive/v${LAPACK_VERSION}.zip"
    FILENAME "v${LAPACK_VERSION}.zip"
    SHA512 7ea3f196f8ec9926072ef8242aabdc24c39065b99d66b71795c07866bf567c72583ccb77504fa0f12277c313d1c1e2c03c4c3cfd67e344bd176d0e36ed6b16e4
)

vcpkg_extract_source_archive(${ARCHIVE})

# lapack is a fortran library, and visual studio does not include a 
# fortran compiler. For this reason we download a copy of mingw and 
# compile lapack with gfortran, and we convert the resulting library 
# to a visual studio-compatible library using the CMAKE_GNUtoMS option 
vcpkg_find_acquire_mingw()

# Use a controlled path to avoid incompatibilities with path containing sh.exe 
set(OLD_PATH $ENV{PATH})
set(ENV{PATH} "${MINGW_PATH};C:/Windows/System32")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    GENERATOR "MinGW Makefiles"
    OPTIONS -DCMAKE_GNUtoMS=ON 
            -DCBLAS=ON 
            -DLAPACKE=ON 
            -DLAPACKE_WITH_TMG=ON
    GFORTRAN_LINKER
)

vcpkg_install_cmake()

# We can just move this files because the relative depths of this directories 
# lib/cmake/lapack-${LAPACK_VERSION} and share/lapack/cmake is the same 
file(COPY ${CURRENT_PACKAGES_DIR}/lib/cmake/lapack-${LAPACK_VERSION}/lapack-config.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/lapack/cmake)
file(COPY ${CURRENT_PACKAGES_DIR}/lib/cmake/lapack-${LAPACK_VERSION}/lapack-config-version.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/lapack/cmake)
file(COPY ${CURRENT_PACKAGES_DIR}/lib/cmake/lapack-${LAPACK_VERSION}/lapack-targets.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/lapack/cmake)
file(COPY ${CURRENT_PACKAGES_DIR}/lib/cmake/lapack-${LAPACK_VERSION}/lapack-targets-release.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/lapack/cmake)

file(READ ${CURRENT_PACKAGES_DIR}/debug/lib/cmake/lapack-${LAPACK_VERSION}/lapack-targets-debug.cmake LAPACK_DEBUG_MODULE)
string(REPLACE "\${_IMPORT_PREFIX}" "\${_IMPORT_PREFIX}/debug" LAPACK_DEBUG_MODULE "${LAPACK_DEBUG_MODULE}")
file(WRITE ${CURRENT_PACKAGES_DIR}/share/lapack/cmake/lapack-targets-debug.cmake "${LAPACK_DEBUG_MODULE}")

# Remove cmake and pkg-config leftovers 
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/cmake)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/pkgconfig)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/cmake)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig)

# Remove debug includes 
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/lapack)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/lapack/LICENSE ${CURRENT_PACKAGES_DIR}/share/lapack/copyright)

# Restore the original path 
set(ENV{PATH} ${OLD_PATH})