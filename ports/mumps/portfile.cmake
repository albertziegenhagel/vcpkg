include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/MUMPS_5.1.2)
vcpkg_download_distfile(ARCHIVE
    URLS
        "http://mumps.enseeiht.fr/MUMPS_5.1.2.tar.gz"
        "http://graal.ens-lyon.fr/MUMPS/MUMPS_5.1.2.tar.gz"
    FILENAME "MUMPS_5.1.2.tar.gz"
    SHA512 38a63b14a8df835be68b5fa310b39aa1815799220d56c176e4005797800959e9e08c9a6bf11d308ab82ea40b6f34d36072cebe7c1de39e0c314eb138b93f1b74
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
