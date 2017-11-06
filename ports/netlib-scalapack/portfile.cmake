include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/scalapack-2.0.2)
vcpkg_download_distfile(ARCHIVE
    URLS "http://www.netlib.org/scalapack/scalapack-2.0.2.tgz"
    FILENAME "scalapack-2.0.2.tgz"
    SHA512 92c71d3de0900955511c527ab3ca57ff69d6d9edc390e69f93ac3769d32ce83a714326bcb6218c8c74b8874be2fdc8aad5e42c912a12581e8d4ce8829ea39248
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/fix-root-cmakelists.patch
        ${CMAKE_CURRENT_LIST_DIR}/disable-pblas-testing.patch
        ${CMAKE_CURRENT_LIST_DIR}/disable-pblas-timing-testing.patch
        ${CMAKE_CURRENT_LIST_DIR}/disable-redist-testing.patch
        ${CMAKE_CURRENT_LIST_DIR}/disable-building-fortran-to-separate-lib.patch
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindMPI.cmake DESTINATION ${SOURCE_PATH}/CMAKE)

vcpkg_enable_fortran()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
        -DBUILD_TESTING=OFF
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

# file(RENAME ${CURRENT_PACKAGES_DIR}/share/scalapack ${CURRENT_PACKAGES_DIR}/share/netlib-scalapack)

file(READ ${CURRENT_PACKAGES_DIR}/debug/share/scalapack/scalapack-targets-debug.cmake SCALAPACK_DEBUG_MODULE)
string(REPLACE "\${_IMPORT_PREFIX}" "\${_IMPORT_PREFIX}/debug" SCALAPACK_DEBUG_MODULE "${SCALAPACK_DEBUG_MODULE}")
file(WRITE ${CURRENT_PACKAGES_DIR}/share/scalapack/scalapack-targets-debug.cmake "${SCALAPACK_DEBUG_MODULE}")

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/pkgconfig)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/netlib-scalapack)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/netlib-scalapack/LICENSE ${CURRENT_PACKAGES_DIR}/share/netlib-scalapack/copyright)
