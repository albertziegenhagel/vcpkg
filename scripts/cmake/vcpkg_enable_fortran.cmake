
function(_vcpkg_load_environment_from_batch)
    cmake_parse_arguments(_lefb "" "BATCH_FILE_PATH" "ARGUMENTS" ${ARGN})

    # Get original environment
    vcpkg_execute_required_process(
        COMMAND "${CMAKE_COMMAND}" "-E" "environment"
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
        LOGNAME environment-initial
    )
    file(READ ${CURRENT_BUILDTREES_DIR}/environment-initial-out.log ENVIRONMENT_INITIAL)

    # Get modified envirnoment
    string (REPLACE ";" " " SPACE_SEPARATED_ARGUMENTS "${_lefb_ARGUMENTS}")
    file(WRITE ${CURRENT_BUILDTREES_DIR}/get-modified-environment.bat "call \"${_lefb_BATCH_FILE_PATH}\" ${SPACE_SEPARATED_ARGUMENTS}\n\"${CMAKE_COMMAND}\" -E environment")
    vcpkg_execute_required_process(
        COMMAND "cmd" "/c" "${CURRENT_BUILDTREES_DIR}/get-modified-environment.bat"
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
        LOGNAME environment-after
    )
    file(READ ${CURRENT_BUILDTREES_DIR}/environment-after-out.log ENVIRONMENT_AFTER)
    
    # Escape characters that have a special meaning in CMake strings.
    string(REPLACE "\\" "/"     ENVIRONMENT_INITIAL "${ENVIRONMENT_INITIAL}")
    string(REPLACE ";"  "\\\\;" ENVIRONMENT_INITIAL "${ENVIRONMENT_INITIAL}")
    string(REPLACE "\n" ";"     ENVIRONMENT_INITIAL "${ENVIRONMENT_INITIAL}")

    string(REPLACE "\\" "/"     ENVIRONMENT_AFTER "${ENVIRONMENT_AFTER}")
    string(REPLACE ";"  "\\\\;" ENVIRONMENT_AFTER "${ENVIRONMENT_AFTER}")
    string(REPLACE "\n" ";"     ENVIRONMENT_AFTER "${ENVIRONMENT_AFTER}")

    # Apply the environment changes to the current CMake environment
    foreach(AFTER_LINE ${ENVIRONMENT_AFTER})
        if("${AFTER_LINE}" MATCHES "^([^=]+)=(.+)$")
            set(AFTER_VAR_NAME "${CMAKE_MATCH_1}")
            set(AFTER_VAR_VALUE "${CMAKE_MATCH_2}")

            set(FOUND "FALSE")
            foreach(INITIAL_LINE ${ENVIRONMENT_INITIAL})
                if("${INITIAL_LINE}" MATCHES "^([^=]+)=(.+)$")
                    set(INITIAL_VAR_NAME "${CMAKE_MATCH_1}")
                    set(INITIAL_VAR_VALUE "${CMAKE_MATCH_2}")
                    
                    if("${AFTER_VAR_NAME}" STREQUAL "${INITIAL_VAR_NAME}")
                        set(FOUND "TRUE")
                        if(NOT "${AFTER_VAR_VALUE}" STREQUAL "${INITIAL_VAR_VALUE}")
                            
                            # Variable has been modified
                            # NOTE: we do not revert the escape changes that have previously been applied
                            #       since the only change that should be visible in a single environment variable
                            #       should be a conversion from `\` to `/` and this should not have any effect on
                            #       windows paths.
                            set(ENV{${AFTER_VAR_NAME}} ${AFTER_VAR_VALUE})
                        endif()
                    endif()
                endif()
            endforeach()

            if(NOT ${FOUND})
                # Variable has been added
                set(ENV{${AFTER_VAR_NAME}} ${AFTER_VAR_VALUE})
            endif()
        endif()
    endforeach()
endfunction()

function(_vcpkg_find_and_load_intel_fortran_compiler)

    set(INTEL_VERSIONS 15 16 17 18)

    set(POTENTIAL_PATHS)
    foreach(INTEL_VERSION ${INTEL_VERSIONS})
        if(NOT "$ENV{IFORT_COMPILER${INTEL_VERSION}}" STREQUAL "")
            file(TO_CMAKE_PATH "$ENV{IFORT_COMPILER${INTEL_VERSION}}" "IFORT_COMPILER${INTEL_VERSION}")

            list(APPEND POTENTIAL_PATHS "${IFORT_COMPILER${INTEL_VERSION}}")
        endif()
    endforeach()

    set(CURRENT_VERSION "")
    set(CURRENT_COMPILERVARS_BAT_PATH "NOTFOUND")

    foreach(CURRENT_PATH ${POTENTIAL_PATHS})
        set(COMPILERVARS_BAT_PATH "${CURRENT_PATH}/bin/compilervars.bat")
        if(EXISTS ${COMPILERVARS_BAT_PATH})
            get_filename_component(DIRECTORY_NAME ${CURRENT_PATH} DIRECTORY)
            get_filename_component(DIRECTORY_NAME ${DIRECTORY_NAME} NAME)

            string(REPLACE "_" ";" DIRECTORY_NAME_PARTS ${DIRECTORY_NAME})
            list(GET DIRECTORY_NAME_PARTS -1 VERSION)
            if("${VERSION}" MATCHES "^([0-9]+\.)+[0-9]+$")
                if("${CURRENT_VERSION}" STREQUAL "" OR "${VERSION}" VERSION_GREATER "${CURRENT_VERSION}")
                    set(CURRENT_VERSION ${VERSION})
                    set(CURRENT_COMPILERVARS_BAT_PATH ${COMPILERVARS_BAT_PATH})
                endif()
            endif()
        endif()
    endforeach()

    if(CURRENT_COMPILERVARS_BAT_PATH)
        if(DEFINED ENV{PROCESSOR_ARCHITEW6432})
            set(HOST_ARCHITECTURE $ENV{PROCESSOR_ARCHITEW6432})
        else()
            set(HOST_ARCHITECTURE $ENV{PROCESSOR_ARCHITECTURE})
        endif()
        
        if("$ENV{HOST_ARCHITECTURE}-${VCPKG_TARGET_ARCHITECTURE}" STREQUAL "x86-x86")
            set(INTEL_ARCH "ia32")
        elseif("${HOST_ARCHITECTURE}-${VCPKG_TARGET_ARCHITECTURE}" STREQUAL "x86-x64")
            set(INTEL_ARCH "ia32_intel64")
        elseif("${HOST_ARCHITECTURE}-${VCPKG_TARGET_ARCHITECTURE}" STREQUAL "AMD64-x64")
            set(INTEL_ARCH "intel64")
        else()
            message(FATAL_ERROR "Combination of host and target architecture is not supported by Intel")
        endif()

        if("${VCPKG_PLATFORM_TOOLSET}" STREQUAL "v140")
            set(INTEL_VS "vs2015")
        elseif("${VCPKG_PLATFORM_TOOLSET}" STREQUAL "v141")
            set(INTEL_VS "vs2017")
            # The Intel compilervars.bat expects the environment variable VS2017INSTALLDIR to be present so we set it
            if(NOT "$ENV{VS2017INSTALLDIR}")
                set(ENV{VS2017INSTALLDIR} "$ENV{VSINSTALLDIR}")
            endif()
        else()
            message(FATAL_ERROR "Visual Studio version is not supported by Intel")
        endif()

        _vcpkg_load_environment_from_batch(
            BATCH_FILE_PATH ${CURRENT_COMPILERVARS_BAT_PATH}
            ARGUMENTS
                ${INTEL_ARCH}
                ${INTEL_VS}
        )
    else()
        message(FATAL_ERROR "Could not find Intel Fortran compiler.")
    endif()
endfunction()

function(_vcpkg_find_and_load_pgi_fortran_compiler)
    vcpkg_get_program_files_platform_bitness(PROGRAM_FILES)

    set(PGI_ROOTS "${PROGRAM_FILES}/PGI" "${PROGRAM_FILES}/PGICE")

    set(CURRENT_VERSION "")
    set(CURRENT_PGI_ENV_BAT_PATH "NOTFOUND")

    foreach(PGI_ROOT ${PGI_ROOTS})
        file(GLOB POTENTIAL_PATHS "${PGI_ROOT}/win64/*") # on windows PGI provides x64 host only
        
        foreach(POTENTIAL_PATH ${POTENTIAL_PATHS})
            if(IS_DIRECTORY ${POTENTIAL_PATH})
                set(PGI_ENV_BAT_PATH "${POTENTIAL_PATH}/pgi_env.bat")
                if(EXISTS ${PGI_ENV_BAT_PATH})
                    get_filename_component(VERSION ${POTENTIAL_PATH} NAME)
                    if("${CURRENT_VERSION}" STREQUAL "" OR "${VERSION}" VERSION_GREATER "${CURRENT_VERSION}")
                        set(CURRENT_VERSION ${VERSION})
                        set(CURRENT_PGI_ENV_BAT_PATH ${PGI_ENV_BAT_PATH})
                    endif()
                endif()
            endif()
        endforeach()
    endforeach()

    if(CURRENT_PGI_ENV_BAT_PATH)
        if(NOT "${VCPKG_TARGET_ARCHITECTURE}" STREQUAL "x64")
            message(FATAL_ERROR "PGI Fortran does not support other target architectures than x64")
        endif()

        # NOTE: We do not need to check for the host architecture
        #       since we would not be able to install PGI if the system would not be x64

        _vcpkg_load_environment_from_batch(
            BATCH_FILE_PATH ${CURRENT_PGI_ENV_BAT_PATH}
        )
    else()
        message(FATAL_ERROR "Could not find PGI Fortran compiler.")
    endif()
endfunction()

function(_vcpkg_find_and_load_gnu_fortran_compiler)
  set(MINGW_VERSION "7.1.0")

  if("${VCPKG_TARGET_ARCHITECTURE}" STREQUAL "x86")
    set(URL "https://kent.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/${MINGW_VERSION}/threads-win32/dwarf/i686-${MINGW_VERSION}-release-win32-dwarf-rt_v5-rev2.7z")
    set(ARCHIVE "i686-${MINGW_VERSION}-release-win32-dwarf-rt_v5-rev2.7z")
    set(HASH "a6ec2b0e2a22f6fed6c4d7ad2420726d78afea64f1d5698363e3f7b910ef94cc10898c88130368cbf4b2146eb05d4ae756f330f2605beeef9583448dbb6fe6d6")
    set(MINGW_DIRECTORY_NAME "mingw32")
  elseif(TRIPLET_SYSTEM_ARCH MATCHES "x64")
    set(URL "https://netix.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/${MINGW_VERSION}/threads-win32/seh/x86_64-${MINGW_VERSION}-release-win32-seh-rt_v5-rev2.7z")
    set(ARCHIVE "x86_64-${MINGW_VERSION}-release-win32-seh-rt_v5-rev2.7z")
    set(HASH "19df45d9f1caf2013bd73110548344f6e6e78ecfe37a086d880116e527d385d8f166e9f9be866033e7037fdee9f662ee227f346103f07e488452c37962f7924a")
    set(MINGW_DIRECTORY_NAME "mingw64")
  else()
    message(FATAL "Mingw download not supported for arch ${VCPKG_TARGET_ARCHITECTURE}.")
  endif()

  set(MINGW_PATH "${DOWNLOADS}/tools/mingw/${MINGW_VERSION}")
  set(MINGW_BIN_PATH "${MINGW_PATH}/${MINGW_DIRECTORY_NAME}/bin")

  # Download and extract MinGW if this has not been done yet
  if(NOT EXISTS "${MINGW_BIN_PATH}/gfortran.exe")
    set(ARCHIVE_PATH "${DOWNLOADS}/${ARCHIVE}")

    file(DOWNLOAD "${URL}" "${ARCHIVE_PATH}"
      EXPECTED_HASH SHA512=${HASH}
      SHOW_PROGRESS
    )

    file(MAKE_DIRECTORY "${MINGW_PATH}")

    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xzf ${ARCHIVE_PATH}
      WORKING_DIRECTORY ${MINGW_PATH}
    )
    
    if(NOT EXISTS "${MINGW_BIN_PATH}/gfortran.exe")
      message(FATAL_ERROR
        "Error while trying to get MinGW GNU Fortran. Could not find:\n"
        "  ${MINGW_BIN_PATH}/gfortran.exe"
      )
    endif()
  endif()

  # Append the MinGW directory to PATH
  if(WIN32)
    set(ENVIRONMENT_SEPERATOR "\\;")
  else()
    set(ENVIRONMENT_SEPERATOR ":")
  endif()

  set(ENV{PATH} "$ENV{PATH}${ENVIRONMENT_SEPERATOR}${MINGW_BIN_PATH}")

  # MinGW does not yet support linking against the UCRT, so all binaries compiled by
  # gfortran will link against an old msvcrt.
  # This will disable the post-installation test for the correct runtime-library
  # for all ports that enable the fortran compiler.
  set(VCPKG_POLICY_ALLOW_OBSOLETE_MSVCRT enabled)
endfunction()

## # vcpkg_enable_fortran
##
## Tries to detect a fortran compiler and pulls in the environment to use it.
##
## This functions reads the variable `VCPKG_FORTRAN_COMPILER` to determine which fortran compiler to use.
## Usually this variable should be set in the triplet by the user.
##
## Supported values for `VCPKG_FORTRAN_COMPILER` are
##
##  - `Intel` = Intel Compiler (intel.com)
##  - `PGI` = The Portland Group (pgroup.com)
##  - `GNU` = GNU Compiler Collection (gcc.gnu.org)
##
## If the variable is not set an error will be raised.
##
## ## Usage:
## ```cmake
## vcpkg_enable_fortran()
## ```
##
## ## Examples:
##
## * [lapack](https://github.com/Microsoft/vcpkg/blob/master/ports/lapack/portfile.cmake)
function(vcpkg_enable_fortran)
    if(DEFINED VCPKG_FORTRAN_COMPILER)
        if(VCPKG_FORTRAN_COMPILER STREQUAL "Intel")
            _vcpkg_find_and_load_intel_fortran_compiler()
        elseif(VCPKG_FORTRAN_COMPILER STREQUAL "PGI")
            _vcpkg_find_and_load_pgi_fortran_compiler()
        elseif(VCPKG_FORTRAN_COMPILER STREQUAL "GNU")
            _vcpkg_find_and_load_gnu_fortran_compiler()
        else()
            message(FATAL_ERROR "Unknown fortran compiler \"${VCPKG_FORTRAN_COMPILER}\".")
        endif()
    else()
        message(FATAL_ERROR "No fortran compiler configured. Please see http://vcpkg.readthedocs.io/en/latest/users/triplets/ for valid fortran settings.")
    endif()
    set(VCPKG_FORTRAN_ENABLED ON PARENT_SCOPE)
endfunction()
