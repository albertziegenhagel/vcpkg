# Read a CMake cache variable from a CMakeCache.txt
function(vcpkg_get_cache_variable VAR_NAME CACHE_FILE OUTPUT_VAR)
    set(PATTERN "^${VAR_NAME}:[A-Z]+=(.+)$")
    file(STRINGS ${CACHE_FILE} FOUND_LINES REGEX ${PATTERN})

    foreach(LINE ${FOUND_LINES})
        if(${LINE} MATCHES ${PATTERN})
            set(${OUTPUT_VAR} ${CMAKE_MATCH_1} PARENT_SCOPE)
            break()
        endif()
    endforeach()
endfunction()