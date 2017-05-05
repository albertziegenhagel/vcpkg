#.rst:
# .. command:: vcpkg_find_acquire_mingw
#
#  Find or download a mingw-w64 installation.
#
#  Currently the script supports only x86 and x64 TRIPLET_SYSTEM_ARCH . 
#  The mingw installation is downloaded in ${DOWNLOADS}/tools/mings-${TRIPLET_SYSTEM_ARCH}.
# 
#  The function sets the MINGW_PATH CMake variable that contains the location of 
#  the binaries of mingw-w64. 
# 
#  ::
#  vcpkg_find_acquire_mingw()
#

function(vcpkg_find_acquire_mingw)
  if(TRIPLET_SYSTEM_ARCH MATCHES "x86")
    set(MINGW_BIN_URL "https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/6.3.0/threads-win32/sjlj/i686-6.3.0-release-win32-sjlj-rt_v5-rev1.7z")
    set(FILENAME "i686-6.3.0-release-win32-sjlj-rt_v5-rev1.7z")
    set(SHA512 "debffd9267c0f95162fbc44468475b05f2a4e7ca4774dd3fbf00aef65be19afc0769c1b47fc2a24f79be43ea6939de549b7b65dae9a6dfc3e52ace91da25172d")
  elseif(TRIPLET_SYSTEM_ARCH MATCHES "x64")
    set(MINGW_BIN_URL "https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/6.3.0/threads-win32/sjlj/x86_64-6.3.0-release-win32-sjlj-rt_v5-rev1.7z")
    set(FILENAME "x86_64-6.3.0-release-win32-sjlj-rt_v5-rev1.7z")
    set(SHA512 "05e99e8adaf2cd23878e4c7f1426cf5abf7dd08ae109d03942229a38ab4053cc2860327e621529b5708f32bc3ee292dcd4fae0c4e653790173a6e83420c466c3")
  else()
    message(FATAL "Mingw download not supported for arch ${TRIPLET_SYSTEM_ARCH}.")
  endif()
    
  set(MINGW_INSTALLATION_PATH ${DOWNLOADS}/tools/mingw-${TRIPLET_SYSTEM_ARCH})

  vcpkg_download_distfile(ARCHIVE
    URLS ${MINGW_BIN_URL}
    FILENAME ${FILENAME}
    SHA512 ${SHA512}
  )
  
  vcpkg_extract_source_archive(${ARCHIVE} ${MINGW_INSTALLATION_PATH})
  
  if(${TRIPLET_SYSTEM_ARCH} STREQUAL "x86")
    set(MINGW_PATH ${MINGW_INSTALLATION_PATH}/mingw32/bin PARENT_SCOPE)
  elseif(${TRIPLET_SYSTEM_ARCH} STREQUAL "x64")
    set(MINGW_PATH ${MINGW_INSTALLATION_PATH}/mingw64/bin PARENT_SCOPE)
  endif()
endfunction()
