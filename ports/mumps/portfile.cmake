include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/MUMPS_5.1.1)
vcpkg_download_distfile(ARCHIVE
    URLS
        "http://mumps.enseeiht.fr/MUMPS_5.1.1.tar.gz"
        "http://graal.ens-lyon.fr/MUMPS/MUMPS_5.1.1.tar.gz"
    FILENAME "MUMPS_5.1.1.tar.gz"
    SHA512 145dd61c9164bc50d07c2baf48345a2aca200332c4e359ea8b5b64fbb2027a6556f622a5620585b4852f785ba8e210267585c53634564f712828add2939901a9
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/no-force-upper-fortran-mangling.patch
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})
file(MAKE_DIRECTORY ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindMPI.cmake DESTINATION ${SOURCE_PATH}/cmake)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindParMETIS.cmake DESTINATION ${SOURCE_PATH}/cmake)

vcpkg_enable_fortran()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    # OPTIONS
    #     -DMUMPS_BUILD_FORTRAN_TO_SEPERATE_LIB=ON
    OPTIONS_DEBUG
        -DMUMPS_SKIP_INSTALL_HEADERS=ON
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/mumps)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/mumps/LICENSE ${CURRENT_PACKAGES_DIR}/share/mumps/copyright)
