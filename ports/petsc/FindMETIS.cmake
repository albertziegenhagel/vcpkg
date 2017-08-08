# - Try to find METIS
# Once done this will define
#
#  METIS_FOUND        - system has METIS
#  METIS_INCLUDE_DIRS - include directories for METIS
#  METIS_LIBRARIES    - libraries for METIS
#
# Variables used by this module. They can change the default behaviour and
# need to be set before calling find_package:
#
#  METIS_DIR          - Prefix directory of the METIS installation
#  METIS_INCLUDE_DIR  - Include directory of the METIS installation
#                          (set only if different from ${METIS_DIR}/include)
#  METIS_LIB_DIR      - Library directory of the METIS installation
#                          (set only if different from ${METIS_DIR}/lib)
#  METIS_LIB_SUFFIX   - Also search for non-standard library names with the
#                          given suffix appended


find_path(METIS_INCLUDE_DIR metis.h
  HINTS ${METIS_INCLUDE_DIR} ENV METIS_INCLUDE_DIR ${METIS_DIR} ENV METIS_DIR
  PATH_SUFFIXES include
  DOC "Directory where the METIS header files are located"
)

find_library(METIS_LIBRARY
  NAMES metis metis${METIS_LIB_SUFFIX}
  HINTS ${METIS_LIB_DIR} ENV METIS_LIB_DIR ${METIS_DIR} ENV METIS_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the METIS library is located"
)

# Get METIS version
if(NOT METIS_VERSION_STRING AND METIS_INCLUDE_DIR AND EXISTS "${METIS_INCLUDE_DIR}/metis.h")
  set(version_pattern "^#define[\t ]+METIS_(MAJOR|MINOR)_VERSION[\t ]+([0-9\\.]+)$")
  file(STRINGS "${METIS_INCLUDE_DIR}/metis.h" metis_version REGEX ${version_pattern})

  foreach(match ${metis_version})
    if(METIS_VERSION_STRING)
      set(METIS_VERSION_STRING "${METIS_VERSION_STRING}.")
    endif()
    string(REGEX REPLACE ${version_pattern} "${METIS_VERSION_STRING}\\2" METIS_VERSION_STRING ${match})
    set(METIS_VERSION_${CMAKE_MATCH_1} ${CMAKE_MATCH_2})
  endforeach()
  unset(metis_version)
  unset(version_pattern)
endif()

# Standard package handling
include(FindPackageHandleStandardArgs)
if(CMAKE_VERSION VERSION_GREATER 2.8.2)
  find_package_handle_standard_args(METIS
    REQUIRED_VARS METIS_LIBRARY METIS_INCLUDE_DIR
    VERSION_VAR METIS_VERSION_STRING)
else()
  find_package_handle_standard_args(METIS
    REQUIRED_VARS METIS_LIBRARY METIS_INCLUDE_DIR)
endif()

if(METIS_FOUND)
  set(METIS_LIBRARIES ${METIS_LIBRARY})
  set(METIS_INCLUDE_DIRS ${METIS_INCLUDE_DIR})
endif()

mark_as_advanced(METIS_INCLUDE_DIR METIS_LIBRARY)
