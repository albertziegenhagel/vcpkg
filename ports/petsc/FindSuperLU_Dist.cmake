# - Try to find SUPERLU_DIST
# Once done this will define
#
#  SUPERLU_DIST_FOUND        - system has SUPERLU_DIST
#  SUPERLU_DIST_INCLUDE_DIRS - include directories for SUPERLU_DIST
#  SUPERLU_DIST_LIBRARIES    - libraries for SUPERLU_DIST
#
# Variables used by this module. They can change the default behaviour and
# need to be set before calling find_package:
#
#  SUPERLU_DIST_DIR          - Prefix directory of the SUPERLU_DIST installation
#  SUPERLU_DIST_INCLUDE_DIR  - Include directory of the SUPERLU_DIST installation
#                          (set only if different from ${SUPERLU_DIST_DIR}/include)
#  SUPERLU_DIST_LIB_DIR      - Library directory of the SUPERLU_DIST installation
#                          (set only if different from ${SUPERLU_DIST_DIR}/lib)
#  SUPERLU_DIST_LIB_SUFFIX   - Also search for non-standard library names with the
#                          given suffix appended


find_path(SUPERLU_DIST_INCLUDE_DIR superlu_defs.h
  HINTS ${SUPERLU_DIST_INCLUDE_DIR} ENV SUPERLU_DIST_INCLUDE_DIR ${SUPERLU_DIST_DIR} ENV SUPERLU_DIST_DIR
  PATH_SUFFIXES include
  DOC "Directory where the SUPERLU_DIST header files are located"
)

find_library(SUPERLU_DIST_LIBRARY
  NAMES superlu_dist superlu_dist${SUPERLU_DIST_LIB_SUFFIX}
  HINTS ${SUPERLU_DIST_LIB_DIR} ENV SUPERLU_DIST_LIB_DIR ${SUPERLU_DIST_DIR} ENV SUPERLU_DIST_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the SUPERLU_DIST library is located"
)

# Get SUPERLU_DIST version
if(NOT SUPERLU_DIST_VERSION_STRING AND SUPERLU_DIST_INCLUDE_DIR AND EXISTS "${SUPERLU_DIST_INCLUDE_DIR}/superlu_defs.h")
  set(version_pattern "^#define[\t ]+SUPERLU_DIST_(MAJOR|MINOR|PATCH)_VERSION[\t ]+([0-9\\.]+)$")
  file(STRINGS "${SUPERLU_DIST_INCLUDE_DIR}/superlu_defs.h" superlu_dist_version REGEX ${version_pattern})

  foreach(match ${superlu_dist_version})
    if(SUPERLU_DIST_VERSION_STRING)
      set(SUPERLU_DIST_VERSION_STRING "${SUPERLU_DIST_VERSION_STRING}.")
    endif()
    string(REGEX REPLACE ${version_pattern} "${SUPERLU_DIST_VERSION_STRING}\\2" SUPERLU_DIST_VERSION_STRING ${match})
    set(SUPERLU_DIST_VERSION_${CMAKE_MATCH_1} ${CMAKE_MATCH_2})
  endforeach()
  unset(superlu_dist_version)
  unset(version_pattern)
endif()

# Standard package handling
include(FindPackageHandleStandardArgs)
if(CMAKE_VERSION VERSION_GREATER 2.8.2)
  find_package_handle_standard_args(SUPERLU_DIST
    REQUIRED_VARS SUPERLU_DIST_LIBRARY SUPERLU_DIST_INCLUDE_DIR
    VERSION_VAR SUPERLU_DIST_VERSION_STRING)
else()
  find_package_handle_standard_args(SUPERLU_DIST
    REQUIRED_VARS SUPERLU_DIST_LIBRARY SUPERLU_DIST_INCLUDE_DIR)
endif()

if(SUPERLU_DIST_FOUND)
  set(SUPERLU_DIST_LIBRARIES ${SUPERLU_DIST_LIBRARY})
  set(SUPERLU_DIST_INCLUDE_DIRS ${SUPERLU_DIST_INCLUDE_DIR})
endif()

mark_as_advanced(SUPERLU_DIST_INCLUDE_DIR SUPERLU_DIST_LIBRARY)
