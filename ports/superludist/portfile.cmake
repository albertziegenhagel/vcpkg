include(vcpkg_common_functions)
# set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/superlu_dist_5.1.3)
# vcpkg_download_distfile(ARCHIVE
#     URLS "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_dist_5.1.3.tar.gz"
#     FILENAME "superlu_dist_5.1.3.tar.gz"
#     SHA512 064942171543006047d5379bc47d27d14467a116e8d2fd8dac82283e237757e2afd31a4ad51c2925323c1b59e70e15da38c6b35db3c1d14b520fc02b906704b6
# )
# vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO xiaoyeli/superlu_dist
    REF v5.1.3
    SHA512  63f33fbfb07ffa19697d5ed45a5061a59fadb6daf795bcb34d41372393d1a4bb02a75ebaee49d182a2017056fb4b6d68894ec3cb46736e8a27af9c29843a5b94
    HEAD_REF master
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindParMETIS.cmake DESTINATION ${SOURCE_PATH}/cmake)

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/fix-root-cmakelists.patch
        ${CMAKE_CURRENT_LIST_DIR}/fix-src-cmakelists.patch
        ${CMAKE_CURRENT_LIST_DIR}/fix-internal-compiler-error.patch
        ${CMAKE_CURRENT_LIST_DIR}/fix-invalid-omp-for-loop-1.patch
        ${CMAKE_CURRENT_LIST_DIR}/fix-invalid-omp-for-loop-2.patch
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
  set(ADDITIONAL_OPTIONS -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -Denable_examples=OFF
        -Denable_blaslib=OFF
        -Denable_parmetislib=OFF
        -DXSDK_ENABLE_Fortran=OFF
        ${ADDITIONAL_OPTIONS}
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Handle copyright
file(COPY ${SOURCE_PATH}/License.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/superludist)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/superludist/License.txt ${CURRENT_PACKAGES_DIR}/share/superludist/copyright)
