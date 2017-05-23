function(vcpkg_install_cmake)
    cmake_parse_arguments(_bc "MSVC_64_TOOLSET;DISABLE_PARALLEL" "" "" ${ARGN})

    set(MSVC_EXTRA_ARGS
        "/p:VCPkgLocalAppDataDisabled=true"
        "/p:UseIntelMKL=No"
    )

    # Specifies the architecture of the toolset, NOT the architecture of the produced binary
    # This can help libraries that cause the linker to run out of memory.
    # https://support.microsoft.com/en-us/help/2891057/linker-fatal-error-lnk1102-out-of-memory
    if (_bc_MSVC_64_TOOLSET)
        list(APPEND MSVC_EXTRA_ARGS "/p:PreferredToolArchitecture=x64")
    endif()

    if (NOT _bc_DISABLE_PARALLEL)
        list(APPEND MSVC_EXTRA_ARGS "/m")
    endif()

    vcpkg_get_cache_variable("CMAKE_GENERATOR" "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/CMakeCache.txt" USED_GENERATOR)

    if(USED_GENERATOR STREQUAL "Ninja")
        set(BUILD_ARGS -v) # verbose output
    elseif(USED_GENERATOR STREQUAL "NMake Makefiles")
        set(BUILD_ARGS "")
    else()
        set(BUILD_ARGS ${MSVC_EXTRA_ARGS})
    endif()

    message(STATUS "Package ${TARGET_TRIPLET}-rel")
    vcpkg_execute_required_process(
        COMMAND ${CMAKE_COMMAND} --build . --config Release --target install -- ${BUILD_ARGS}
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
        LOGNAME package-${TARGET_TRIPLET}-rel
    )
    message(STATUS "Package ${TARGET_TRIPLET}-rel done")

    message(STATUS "Package ${TARGET_TRIPLET}-dbg")
    vcpkg_execute_required_process(
        COMMAND ${CMAKE_COMMAND} --build . --config Debug --target install -- ${BUILD_ARGS}
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
        LOGNAME package-${TARGET_TRIPLET}-dbg
    )
    message(STATUS "Package ${TARGET_TRIPLET}-dbg done")
endfunction()
