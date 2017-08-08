# - Try to find ParMETIS
# Once done this will define
#
#  PARMETIS_FOUND        - system has ParMETIS
#  PARMETIS_INCLUDE_DIRS - include directories for ParMETIS
#  PARMETIS_LIBRARIES    - libraries for ParMETIS
#
# Variables used by this module. They can change the default behaviour and
# need to be set before calling find_package:
#
#  PARMETIS_DIR          - Prefix directory of the ParMETIS installation
#  PARMETIS_INCLUDE_DIR  - Include directory of the ParMETIS installation
#                          (set only if different from ${PARMETIS_DIR}/include)
#  PARMETIS_LIB_DIR      - Library directory of the ParMETIS installation
#                          (set only if different from ${PARMETIS_DIR}/lib)
#  PARMETIS_LIB_SUFFIX   - Also search for non-standard library names with the
#                          given suffix appended


find_path(PARMETIS_INCLUDE_DIR parmetis.h
  HINTS ${PARMETIS_INCLUDE_DIR} ENV PARMETIS_INCLUDE_DIR ${PARMETIS_DIR} ENV PARMETIS_DIR
  PATH_SUFFIXES include
  DOC "Directory where the ParMETIS header files are located"
)

find_library(PARMETIS_LIBRARY
  NAMES parmetis parmetis${PARMETIS_LIB_SUFFIX}
  HINTS ${PARMETIS_LIB_DIR} ENV PARMETIS_LIB_DIR ${PARMETIS_DIR} ENV PARMETIS_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the ParMETIS library is located"
)

find_library(METIS_LIBRARY
  NAMES metis metis${PARMETIS_LIB_SUFFIX}
  HINTS ${PARMETIS_LIB_DIR} ENV PARMETIS_LIB_DIR ${PARMETIS_DIR} ENV PARMETIS_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the METIS library is located"
)

# Get ParMETIS version
if(NOT PARMETIS_VERSION_STRING AND PARMETIS_INCLUDE_DIR AND EXISTS "${PARMETIS_INCLUDE_DIR}/parmetis.h")
  set(version_pattern "^#define[\t ]+PARMETIS_(MAJOR|MINOR)_VERSION[\t ]+([0-9\\.]+)$")
  file(STRINGS "${PARMETIS_INCLUDE_DIR}/parmetis.h" parmetis_version REGEX ${version_pattern})

  foreach(match ${parmetis_version})
    if(PARMETIS_VERSION_STRING)
      set(PARMETIS_VERSION_STRING "${PARMETIS_VERSION_STRING}.")
    endif()
    string(REGEX REPLACE ${version_pattern} "${PARMETIS_VERSION_STRING}\\2" PARMETIS_VERSION_STRING ${match})
    set(PARMETIS_VERSION_${CMAKE_MATCH_1} ${CMAKE_MATCH_2})
  endforeach()
  unset(parmetis_version)
  unset(version_pattern)
endif()

# Standard package handling
include(FindPackageHandleStandardArgs)
if(CMAKE_VERSION VERSION_GREATER 2.8.2)
  find_package_handle_standard_args(ParMETIS
    REQUIRED_VARS PARMETIS_LIBRARY PARMETIS_INCLUDE_DIR
    VERSION_VAR PARMETIS_VERSION_STRING)
else()
  find_package_handle_standard_args(ParMETIS
    REQUIRED_VARS PARMETIS_LIBRARY PARMETIS_INCLUDE_DIR)
endif()

if(PARMETIS_FOUND)
  set(PARMETIS_LIBRARIES ${PARMETIS_LIBRARY} ${METIS_LIBRARY})
  set(PARMETIS_INCLUDE_DIRS ${PARMETIS_INCLUDE_DIR})
endif()

mark_as_advanced(PARMETIS_INCLUDE_DIR PARMETIS_LIBRARY METIS_LIBRARY)
