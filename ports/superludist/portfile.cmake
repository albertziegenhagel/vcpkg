include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO xiaoyeli/superlu_dist
    REF v5.2.2
    SHA512  8811c10d156e1e1966f56e52a208aa4272d512a3834eeca59cdcf6d9098fe53f1597a7133e3058e8de04011d3e4dd6be5a9c63a407f08a55120dca66785405df
    HEAD_REF master
)

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/fix-parmetis.patch
        ${CMAKE_CURRENT_LIST_DIR}/fix-windows-build.patch
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -Denable_examples=OFF
        -Denable_tests=OFF
        -Denable_blaslib=OFF
        -Denable_parmetislib=OFF
        -DXSDK_ENABLE_Fortran=OFF
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Handle copyright
file(COPY ${SOURCE_PATH}/License.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/superludist)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/superludist/License.txt ${CURRENT_PACKAGES_DIR}/share/superludist/copyright)
