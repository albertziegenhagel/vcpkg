# - Try to find HYPRE
# Once done this will define
#
#  HYPRE_FOUND        - system has HYPRE
#  HYPRE_INCLUDE_DIRS - include directories for HYPRE
#  HYPRE_LIBRARIES    - libraries for HYPRE
#
# Variables used by this module. They can change the default behaviour and
# need to be set before calling find_package:
#
#  HYPRE_DIR          - Prefix directory of the HYPRE installation
#  HYPRE_INCLUDE_DIR  - Include directory of the HYPRE installation
#                          (set only if different from ${HYPRE_DIR}/include)
#  HYPRE_LIB_DIR      - Library directory of the HYPRE installation
#                          (set only if different from ${HYPRE_DIR}/lib)
#  HYPRE_LIB_SUFFIX   - Also search for non-standard library names with the
#                          given suffix appended


find_path(HYPRE_INCLUDE_DIR HYPRE.h
  HINTS ${HYPRE_INCLUDE_DIR} ENV HYPRE_INCLUDE_DIR ${HYPRE_DIR} ENV HYPRE_DIR
  PATH_SUFFIXES include
  DOC "Directory where the HYPRE header files are located"
)

find_library(HYPRE_LIBRARY
  NAMES HYPRE HYPRE${HYPRE_LIB_SUFFIX}
  HINTS ${HYPRE_LIB_DIR} ENV HYPRE_LIB_DIR ${HYPRE_DIR} ENV HYPRE_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the HYPRE library is located"
)

# Get HYPRE version
if(NOT HYPRE_VERSION_STRING AND HYPRE_INCLUDE_DIR AND EXISTS "${HYPRE_INCLUDE_DIR}/HYPRE_config.h")
  set(version_pattern "^#define[\t ]+HYPRE_RELEASE_VERSION[\t ]+([0-9\\.]+)$")
  file(STRINGS "${HYPRE_INCLUDE_DIR}/HYPRE_config.h" hypre_version REGEX ${version_pattern})

  string(REGEX MATCH ${version_pattern} HYPRE_VERSION_STRING ${hypre_version})
  set(HYPRE_VERSION_STRING ${CMAKE_MATCH_1})

  unset(hypre_version)
  unset(version_pattern)
endif()

# Standard package handling
include(FindPackageHandleStandardArgs)
if(CMAKE_VERSION VERSION_GREATER 2.8.2)
  find_package_handle_standard_args(HYPRE
    REQUIRED_VARS HYPRE_LIBRARY HYPRE_INCLUDE_DIR
    VERSION_VAR HYPRE_VERSION_STRING)
else()
  find_package_handle_standard_args(HYPRE
    REQUIRED_VARS HYPRE_LIBRARY HYPRE_INCLUDE_DIR)
endif()

if(HYPRE_FOUND)
  set(HYPRE_LIBRARIES ${HYPRE_LIBRARY})
  set(HYPRE_INCLUDE_DIRS ${HYPRE_INCLUDE_DIR})
endif()

mark_as_advanced(HYPRE_INCLUDE_DIR HYPRE_LIBRARY)
