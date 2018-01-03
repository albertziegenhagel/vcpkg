## # vcpkg_configure_cmake
##
## Configure CMake for Debug and Release builds of a project.
##
## ## Usage
## ```cmake
## vcpkg_configure_cmake(
##     SOURCE_PATH <${SOURCE_PATH}>
##     [PREFER_NINJA]
##     [GENERATOR <"NMake Makefiles">]
##     [OPTIONS <-DUSE_THIS_IN_ALL_BUILDS=1>...]
##     [OPTIONS_RELEASE <-DOPTIMIZE=1>...]
##     [OPTIONS_DEBUG <-DDEBUGGABLE=1>...]
## )
## ```
##
## ## Parameters
## ### SOURCE_PATH
## Specifies the directory containing the `CMakeLists.txt`. By convention, this is usually set in the portfile as the variable `SOURCE_PATH`.
##
## ### PREFER_NINJA
## Indicates that, when available, Vcpkg should use Ninja to perform the build. This should be specified unless the port is known to not work under Ninja.
##
## ### GENERATOR
## Specifies the precise generator to use.
##
## This is useful if some project-specific buildsystem has been wrapped in a cmake script that won't perform an actual build. If used for this purpose, it should be set to "NMake Makefiles".
##
## ### OPTIONS
## Additional options passed to CMake during the configuration.
##
## ### OPTIONS_RELEASE
## Additional options passed to CMake during the Release configuration. These are in addition to `OPTIONS`.
##
## ### OPTIONS_DEBUG
## Additional options passed to CMake during the Debug configuration. These are in addition to `OPTIONS`.
##
## ## Notes
## This command supplies many common arguments to CMake. To see the full list, examine the source.
##
## ## Examples
##
## * [zlib](https://github.com/Microsoft/vcpkg/blob/master/ports/zlib/portfile.cmake)
## * [cpprestsdk](https://github.com/Microsoft/vcpkg/blob/master/ports/cpprestsdk/portfile.cmake)
## * [poco](https://github.com/Microsoft/vcpkg/blob/master/ports/poco/portfile.cmake)
## * [opencv](https://github.com/Microsoft/vcpkg/blob/master/ports/opencv/portfile.cmake)
function(vcpkg_configure_cmake)
    cmake_parse_arguments(_csc "PREFER_NINJA" "SOURCE_PATH;GENERATOR" "OPTIONS;OPTIONS_DEBUG;OPTIONS_RELEASE" ${ARGN})

    if(NOT VCPKG_PLATFORM_TOOLSET)
        message(FATAL_ERROR "Vcpkg has been updated with VS2017 support, however you need to rebuild vcpkg.exe by re-running bootstrap-vcpkg.bat\n")
    endif()

    if(DEFINED ENV{PROCESSOR_ARCHITEW6432})
        set(_csc_HOST_ARCHITECTURE $ENV{PROCESSOR_ARCHITEW6432})
    else()
        set(_csc_HOST_ARCHITECTURE $ENV{PROCESSOR_ARCHITECTURE})
    endif()

    if(_csc_GENERATOR)
        set(GENERATOR ${_csc_GENERATOR})
    elseif(VCPKG_FORTRAN_ENABLED AND DEFINED VCPKG_FORTRAN_COMPILER AND VCPKG_FORTRAN_COMPILER STREQUAL Flang)
        # Flang is not supported by Ninja, nor Visual Studio so we use NMake here
        set(GENERATOR "NMake Makefiles")
    elseif(_csc_PREFER_NINJA AND NOT VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" AND NOT _csc_HOST_ARCHITECTURE STREQUAL "x86")
        set(GENERATOR "Ninja")
    elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "x86" AND VCPKG_PLATFORM_TOOLSET MATCHES "v120")
        set(GENERATOR "Visual Studio 12 2013")
    elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "x64" AND VCPKG_PLATFORM_TOOLSET MATCHES "v120")
        set(GENERATOR "Visual Studio 12 2013 Win64")
    elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "arm" AND VCPKG_PLATFORM_TOOLSET MATCHES "v120")
        set(GENERATOR "Visual Studio 12 2013 ARM")
    elseif(VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
        set(GENERATOR "Ninja")
    elseif(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" AND VCPKG_TARGET_ARCHITECTURE MATCHES "x86" AND VCPKG_PLATFORM_TOOLSET MATCHES "v140")
        set(GENERATOR "Visual Studio 14 2015")
    elseif(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" AND VCPKG_TARGET_ARCHITECTURE MATCHES "x64" AND VCPKG_PLATFORM_TOOLSET MATCHES "v140")
        set(GENERATOR "Visual Studio 14 2015 Win64")
    elseif(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" AND VCPKG_TARGET_ARCHITECTURE MATCHES "arm" AND VCPKG_PLATFORM_TOOLSET MATCHES "v140")
        set(GENERATOR "Visual Studio 14 2015 ARM")
    elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "x86" AND VCPKG_PLATFORM_TOOLSET MATCHES "v140")
        set(GENERATOR "Visual Studio 14 2015")
    elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "x64" AND VCPKG_PLATFORM_TOOLSET MATCHES "v140")
        set(GENERATOR "Visual Studio 14 2015 Win64")
    elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "arm" AND VCPKG_PLATFORM_TOOLSET MATCHES "v140")
        set(GENERATOR "Visual Studio 14 2015 ARM")

    elseif(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" AND VCPKG_TARGET_ARCHITECTURE MATCHES "x86" AND VCPKG_PLATFORM_TOOLSET MATCHES "v141")
        set(GENERATOR "Visual Studio 15 2017")
    elseif(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" AND VCPKG_TARGET_ARCHITECTURE MATCHES "x64" AND VCPKG_PLATFORM_TOOLSET MATCHES "v141")
        set(GENERATOR "Visual Studio 15 2017 Win64")
    elseif(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" AND VCPKG_TARGET_ARCHITECTURE STREQUAL "arm" AND VCPKG_PLATFORM_TOOLSET MATCHES "v141")
        set(GENERATOR "Visual Studio 15 2017 ARM")
    elseif(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" AND VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64" AND VCPKG_PLATFORM_TOOLSET MATCHES "v141")
        set(GENERATOR "Visual Studio 15 2017")    
        set(ARCH "ARM64")
    elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "x86" AND VCPKG_PLATFORM_TOOLSET MATCHES "v141")
        set(GENERATOR "Visual Studio 15 2017")
    elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "x64" AND VCPKG_PLATFORM_TOOLSET MATCHES "v141")
        set(GENERATOR "Visual Studio 15 2017 Win64")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm" AND VCPKG_PLATFORM_TOOLSET MATCHES "v141")
        set(GENERATOR "Visual Studio 15 2017 ARM")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64" AND VCPKG_PLATFORM_TOOLSET MATCHES "v141")
        set(GENERATOR "Visual Studio 15 2017")
        set(ARCH "ARM64")
    else()
        message(FATAL_ERROR "Unable to determine appropriate generator for: ${VCPKG_CMAKE_SYSTEM_NAME}-${VCPKG_TARGET_ARCHITECTURE}-${VCPKG_PLATFORM_TOOLSET}")
    endif()
    
    # If we use Ninja, make sure it's on PATH
    if(GENERATOR STREQUAL "Ninja")
        vcpkg_find_acquire_program(NINJA)
        get_filename_component(NINJA_PATH ${NINJA} DIRECTORY)
        set(ENV{PATH} "$ENV{PATH};${NINJA_PATH}")
    endif()

    file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)

    if(DEFINED VCPKG_CMAKE_SYSTEM_NAME)
        list(APPEND _csc_OPTIONS "-DCMAKE_SYSTEM_NAME=${VCPKG_CMAKE_SYSTEM_NAME}")
    endif()
    if(DEFINED VCPKG_CMAKE_SYSTEM_VERSION)
        list(APPEND _csc_OPTIONS "-DCMAKE_SYSTEM_VERSION=${VCPKG_CMAKE_SYSTEM_VERSION}")
    endif()

    if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        list(APPEND _csc_OPTIONS -DBUILD_SHARED_LIBS=ON)
    elseif(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
        list(APPEND _csc_OPTIONS -DBUILD_SHARED_LIBS=OFF)
    else()
        message(FATAL_ERROR "Invalid setting for VCPKG_LIBRARY_LINKAGE: \"${VCPKG_LIBRARY_LINKAGE}\". It must be \"static\" or \"dynamic\"")
    endif()

    if((NOT DEFINED VCPKG_CXX_FLAGS_DEBUG AND NOT DEFINED VCPKG_C_FLAGS_DEBUG) OR
        (DEFINED VCPKG_CXX_FLAGS_DEBUG AND DEFINED VCPKG_C_FLAGS_DEBUG))
    else()
        message(FATAL_ERROR "You must set both the VCPKG_CXX_FLAGS_DEBUG and VCPKG_C_FLAGS_DEBUG")
    endif()
    if((NOT DEFINED VCPKG_CXX_FLAGS_RELEASE AND NOT DEFINED VCPKG_C_FLAGS_RELEASE) OR
        (DEFINED VCPKG_CXX_FLAGS_RELEASE AND DEFINED VCPKG_C_FLAGS_RELEASE))
    else()
        message(FATAL_ERROR "You must set both the VCPKG_CXX_FLAGS_RELEASE and VCPKG_C_FLAGS_RELEASE")
    endif()
    if((NOT DEFINED VCPKG_CXX_FLAGS AND NOT DEFINED VCPKG_C_FLAGS) OR
        (DEFINED VCPKG_CXX_FLAGS AND DEFINED VCPKG_C_FLAGS))
    else()
        message(FATAL_ERROR "You must set both the VCPKG_CXX_FLAGS and VCPKG_C_FLAGS")
    endif()

    if(VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
        list(APPEND _csc_OPTIONS "-DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=${VCPKG_CHAINLOAD_TOOLCHAIN_FILE}")
    else()
        if(VCPKG_FORTRAN_ENABLED AND DEFINED VCPKG_FORTRAN_COMPILER AND VCPKG_FORTRAN_COMPILER STREQUAL Intel)
            # Make sure the name mangling of Intel Fortran generated symbols is all lowercase with underscore suffix
            # because this is assumed by many libraries (that e.g. consume BLAS/LAPACK)
            set(ENV{FFLAGS} "$ENV{FFLAGS} /names:lowercase /assume:underscore")

            # When using the Intel and VS2017 command line environments together there is a bug when
            # using cl and some standard headers are included (e.g. stdint.h). This is because Intel does
            # not handle the changed directory structure of the runtime headers between VS2015 and VS2017 correctly.
            # The following code works around those issues. This is true as of Intel 2017.4 and VS2017.3.
            if(VCPKG_PLATFORM_TOOLSET STREQUAL "v141")
                file(TO_CMAKE_PATH "$ENV{VCToolsInstallDir}" VCToolsInstallDir)
                string(APPEND VCPKG_CXX_FLAGS " /D__MS_VC_INSTALL_PATH=\"${VCToolsInstallDir}\"")
                string(APPEND VCPKG_C_FLAGS " /D__MS_VC_INSTALL_PATH=\"${VCToolsInstallDir}\"")
            endif()
        endif()
        
        if(VCPKG_FORTRAN_ENABLED AND DEFINED VCPKG_FORTRAN_COMPILER AND VCPKG_FORTRAN_COMPILER STREQUAL Flang)
            # Make sure that CMake uses the correct compilers:
            # while we want to use flang as Fortran compiler we want to keep cl for C and C++
            list(APPEND _csc_OPTIONS
                "-DCMAKE_Fortran_COMPILER=flang"
                "-DCMAKE_C_COMPILER=cl"
                "-DCMAKE_CXX_COMPILER=cl"
            )
        endif()

        # When using GNU gfortran as Fortran compiler CMake requires to use gcc and g++ as C and C++ compilers
        # so we should not set all the other C and C++ compiler flags
        if(VCPKG_FORTRAN_ENABLED AND DEFINED VCPKG_FORTRAN_COMPILER AND VCPKG_FORTRAN_COMPILER STREQUAL GNU)
            list(APPEND _csc_OPTIONS
                "-DCMAKE_GNUtoMS=ON"
            )
        else()
            set(VCPKG_CXX_FLAGS " /DWIN32 /D_WINDOWS /W3 /utf-8 /GR /EHsc /MP ${VCPKG_CXX_FLAGS}")
            set(VCPKG_C_FLAGS " /DWIN32 /D_WINDOWS /W3 /utf-8 /MP ${VCPKG_C_FLAGS}")
            if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
                list(APPEND _csc_OPTIONS_DEBUG
                    "-DCMAKE_CXX_FLAGS_DEBUG=/D_DEBUG /MDd /Z7 /Ob0 /Od /RTC1 ${VCPKG_CXX_FLAGS_DEBUG}"
                    "-DCMAKE_C_FLAGS_DEBUG=/D_DEBUG /MDd /Z7 /Ob0 /Od /RTC1 ${VCPKG_C_FLAGS_DEBUG}"
                )
                list(APPEND _csc_OPTIONS_RELEASE
                    "-DCMAKE_CXX_FLAGS_RELEASE=/MD /O2 /Oi /Gy /DNDEBUG /Z7 ${VCPKG_CXX_FLAGS_RELEASE}"
                    "-DCMAKE_C_FLAGS_RELEASE=/MD /O2 /Oi /Gy /DNDEBUG /Z7 ${VCPKG_C_FLAGS_RELEASE}"
                )
            elseif(VCPKG_CRT_LINKAGE STREQUAL "static")
                list(APPEND _csc_OPTIONS_DEBUG
                    "-DCMAKE_CXX_FLAGS_DEBUG=/D_DEBUG /MTd /Z7 /Ob0 /Od /RTC1 ${VCPKG_CXX_FLAGS_DEBUG}"
                    "-DCMAKE_C_FLAGS_DEBUG=/D_DEBUG /MTd /Z7 /Ob0 /Od /RTC1 ${VCPKG_C_FLAGS_DEBUG}"
                )
                list(APPEND _csc_OPTIONS_RELEASE
                    "-DCMAKE_CXX_FLAGS_RELEASE=/MT /O2 /Oi /Gy /DNDEBUG /Z7 ${VCPKG_CXX_FLAGS_RELEASE}"
                    "-DCMAKE_C_FLAGS_RELEASE=/MT /O2 /Oi /Gy /DNDEBUG /Z7 ${VCPKG_C_FLAGS_RELEASE}"
                )
            else()
                message(FATAL_ERROR "Invalid setting for VCPKG_CRT_LINKAGE: \"${VCPKG_CRT_LINKAGE}\". It must be \"static\" or \"dynamic\"")
            endif()

            list(APPEND _csc_OPTIONS_RELEASE
                "-DCMAKE_SHARED_LINKER_FLAGS_RELEASE=/DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${VCPKG_LINKER_FLAGS}"
                "-DCMAKE_EXE_LINKER_FLAGS_RELEASE=/DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${VCPKG_LINKER_FLAGS}"
            )
            list(APPEND _csc_OPTIONS
                "-DCMAKE_CXX_FLAGS=${VCPKG_CXX_FLAGS}"
                "-DCMAKE_C_FLAGS=${VCPKG_C_FLAGS}"
            )
        endif()
    endif()

    list(APPEND _csc_OPTIONS
        "-DVCPKG_TARGET_TRIPLET=${TARGET_TRIPLET}"
        "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON"
        "-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON"
        "-DCMAKE_FIND_PACKAGE_NO_SYSTEM_PACKAGE_REGISTRY=ON"
        "-DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=TRUE"
        "-DCMAKE_VERBOSE_MAKEFILE=ON"
        "-DVCPKG_APPLOCAL_DEPS=OFF"
        "-DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT_DIR}/scripts/buildsystems/vcpkg.cmake"
        "-DCMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION=ON"
    )

    if(DEFINED ARCH)
        list(APPEND _csc_OPTIONS
            "-A${ARCH}"
        )
    endif()

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        message(STATUS "Configuring ${TARGET_TRIPLET}-rel")
        file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
        vcpkg_execute_required_process(
            COMMAND ${CMAKE_COMMAND} ${_csc_SOURCE_PATH} ${_csc_OPTIONS} ${_csc_OPTIONS_RELEASE}
                -G ${GENERATOR}
                -DCMAKE_BUILD_TYPE=Release
                -DCMAKE_INSTALL_PREFIX=${CURRENT_PACKAGES_DIR}
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
            LOGNAME config-${TARGET_TRIPLET}-rel
        )
        message(STATUS "Configuring ${TARGET_TRIPLET}-rel done")
    endif()

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        message(STATUS "Configuring ${TARGET_TRIPLET}-dbg")
        file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
        vcpkg_execute_required_process(
            COMMAND ${CMAKE_COMMAND} ${_csc_SOURCE_PATH} ${_csc_OPTIONS} ${_csc_OPTIONS_DEBUG}
                -G ${GENERATOR}
                -DCMAKE_BUILD_TYPE=Debug
                -DCMAKE_INSTALL_PREFIX=${CURRENT_PACKAGES_DIR}/debug
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
            LOGNAME config-${TARGET_TRIPLET}-dbg
        )
        message(STATUS "Configuring ${TARGET_TRIPLET}-dbg done")
    endif()

    set(_VCPKG_CMAKE_GENERATOR "${GENERATOR}" PARENT_SCOPE)
endfunction()