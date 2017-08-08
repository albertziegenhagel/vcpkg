# - Try to find MUMPS
# Once done this will define
#
#  MUMPS_FOUND        - system has MUMPS
#  MUMPS_INCLUDE_DIRS - include directories for MUMPS
#  MUMPS_LIBRARIES    - libraries for MUMPS
#
# Variables used by this module. They can change the default behaviour and
# need to be set before calling find_package:
#
#  MUMPS_DIR          - Prefix directory of the MUMPS installation
#  MUMPS_INCLUDE_DIR  - Include directory of the MUMPS installation
#                          (set only if different from ${MUMPS_DIR}/include)
#  MUMPS_LIB_DIR      - Library directory of the MUMPS installation
#                          (set only if different from ${MUMPS_DIR}/lib)
#  MUMPS_LIB_SUFFIX   - Also search for non-standard library names with the
#                          given suffix appended


find_path(MUMPS_INCLUDE_DIR smumps_c.h
  HINTS ${MUMPS_INCLUDE_DIR} ENV MUMPS_INCLUDE_DIR ${MUMPS_DIR} ENV MUMPS_DIR
  PATH_SUFFIXES include
  DOC "Directory where the MUMPS header files are located"
)

find_library(MUMPS_COMMON_LIBRARY
  NAMES mumps_common mumps${MUMPS_LIB_SUFFIX}
  HINTS ${MUMPS_LIB_DIR} ENV MUMPS_LIB_DIR ${MUMPS_DIR} ENV MUMPS_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the COMMON MUMPS library is located"
)

find_library(SMUMPS_LIBRARY
  NAMES smumps smumps${MUMPS_LIB_SUFFIX}
  HINTS ${MUMPS_LIB_DIR} ENV MUMPS_LIB_DIR ${MUMPS_DIR} ENV MUMPS_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the SMUMPS library is located"
)

find_library(DMUMPS_LIBRARY
  NAMES dmumps dmumps${MUMPS_LIB_SUFFIX}
  HINTS ${MUMPS_LIB_DIR} ENV MUMPS_LIB_DIR ${MUMPS_DIR} ENV MUMPS_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the DMUMPS library is located"
)

find_library(CMUMPS_LIBRARY
  NAMES cmumps cmumps${MUMPS_LIB_SUFFIX}
  HINTS ${MUMPS_LIB_DIR} ENV MUMPS_LIB_DIR ${MUMPS_DIR} ENV MUMPS_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the CMUMPS library is located"
)

find_library(ZMUMPS_LIBRARY
  NAMES zmumps zmumps${MUMPS_LIB_SUFFIX}
  HINTS ${MUMPS_LIB_DIR} ENV MUMPS_LIB_DIR ${MUMPS_DIR} ENV MUMPS_DIR
  PATH_SUFFIXES lib
  DOC "Directory where the ZMUMPS library is located"
)

# Get MUMPS version
if(NOT MUMPS_VERSION_STRING AND MUMPS_INCLUDE_DIR AND EXISTS "${MUMPS_INCLUDE_DIR}/smumps_c.h")
  set(version_pattern "^#define[\t ]+MUMPS_VERSION[\t ]+\"([0-9\\.]+)\"[\t ]*$")
  file(STRINGS "${MUMPS_INCLUDE_DIR}/smumps_c.h" mumps_version REGEX ${version_pattern})

  string(REGEX MATCH ${version_pattern} MUMPS_VERSION_STRING ${mumps_version})
  set(MUMPS_VERSION_STRING ${CMAKE_MATCH_1})

  unset(mumps_version)
  unset(version_pattern)
endif()

# Standard package handling
include(FindPackageHandleStandardArgs)
if(CMAKE_VERSION VERSION_GREATER 2.8.2)
  find_package_handle_standard_args(MUMPS
    REQUIRED_VARS MUMPS_COMMON_LIBRARY SMUMPS_LIBRARY DMUMPS_LIBRARY CMUMPS_LIBRARY ZMUMPS_LIBRARY MUMPS_INCLUDE_DIR
    VERSION_VAR MUMPS_VERSION_STRING)
else()
  find_package_handle_standard_args(MUMPS
    REQUIRED_VARS MUMPS_COMMON_LIBRARY SMUMPS_LIBRARY DMUMPS_LIBRARY CMUMPS_LIBRARY ZMUMPS_LIBRARY MUMPS_INCLUDE_DIR)
endif()

if(MUMPS_FOUND)
  set(MUMPS_LIBRARIES ${MUMPS_COMMON_LIBRARY} ${SMUMPS_LIBRARY} ${DMUMPS_LIBRARY} ${CMUMPS_LIBRARY} ${ZMUMPS_LIBRARY})
  set(MUMPS_INCLUDE_DIRS ${MUMPS_INCLUDE_DIR})
endif()

mark_as_advanced(MUMPS_INCLUDE_DIR MUMPS_COMMON_LIBRARY SMUMPS_LIBRARY DMUMPS_LIBRARY CMUMPS_LIBRARY ZMUMPS_LIBRARY)
