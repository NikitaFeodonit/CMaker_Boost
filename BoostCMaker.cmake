# ****************************************************************************
#  Project:  BoostCMaker
#  Purpose:  A CMake build script for Boost Libraries
#  Author:   NikitaFeodonit, nfeodonit@yandex.com
# ****************************************************************************
#    Copyright (c) 2017 NikitaFeodonit
#
#    This file is part of the BoostCMaker project.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published
#    by the Free Software Foundation, either version 3 of the License,
#    or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <http://www.gnu.org/licenses/>.
# ****************************************************************************


# To find bcm source dir.
# TODO: prevent multiply includes for CMAKE_MODULE_PATH
set(bcm_SRC_DIR ${CMAKE_CURRENT_LIST_DIR})
list(APPEND CMAKE_MODULE_PATH "${bcm_SRC_DIR}/cmake/modules")

# See description for "bcm_boost_cmaker()" for params and vars.
function(BoostCMaker)
  cmake_minimum_required(VERSION 3.2)

  cmake_parse_arguments(boost "" "VERSION" "COMPONENTS" "${ARGV}")
  # -> boost_VERSION
  # -> boost_COMPONENTS

  # To prevent the list expansion on an argument with ';'.
  # See also
  # http://stackoverflow.com/a/20989991
  # http://stackoverflow.com/a/20985057
  bcm_print_var_value(boost_COMPONENTS)
  string (REPLACE ";" " " boost_COMPONENTS "${boost_COMPONENTS}")
  bcm_print_var_value(boost_COMPONENTS)


  #-----------------------------------------------------------------------
  # Build dirs
  #-----------------------------------------------------------------------

  set(bcm_bin_dir_name "BoostCMaker")
  set(bcm_bin_dir "${CMAKE_CURRENT_BINARY_DIR}/${bcm_bin_dir_name}")


  #-----------------------------------------------------------------------
  # Build args
  #-----------------------------------------------------------------------

  set(bcm_CMAKE_ARGS)

  # Standard CMake vars
  if(CMAKE_INSTALL_PREFIX)
    list(APPEND bcm_CMAKE_ARGS
      -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    )
  endif()
  if(CMAKE_BUILD_TYPE)
    list(APPEND bcm_CMAKE_ARGS
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    )
  endif()
  if(BUILD_SHARED_LIBS)
    list(APPEND bcm_CMAKE_ARGS
      -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
    )
  endif()

  if(CMAKE_TOOLCHAIN_FILE)
    list(APPEND bcm_CMAKE_ARGS
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    )
  endif()
  if(CMAKE_GENERATOR)
    list(APPEND bcm_CMAKE_ARGS
      -G "${CMAKE_GENERATOR}" # TODO: check it with debug message
    )
  endif()
  if(CMAKE_MAKE_PROGRAM)
    list(APPEND bcm_CMAKE_ARGS
      -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
    )
  endif()

  # Vars from FindBoost.cmake
  # TODO: add more vars
  if(Boost_USE_STATIC_LIBS)
    list(APPEND bcm_CMAKE_ARGS
      -DBoost_USE_STATIC_LIBS=${Boost_USE_STATIC_LIBS}
    )
  endif()
  if(Boost_USE_MULTITHREADED)
    list(APPEND bcm_CMAKE_ARGS
      -DBoost_USE_MULTITHREADED=${Boost_USE_MULTITHREADED}
    )
  endif()
  
  # Android specifics
  if(ANDROID)
    # TODO: get new vars from NDK's toolchain
    # TODO: check if var is defined
  
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID=ON
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_NDK=${ANDROID_NDK}
    )

    # Configurable variables from
    # android-sdk/cmake/3.6.3155560/android.toolchain.cmake
    # (package version 3.6.3155560).
    # Modeled after the ndk-build system.
    # For any variables defined in:
    #         https://developer.android.com/ndk/guides/android_mk.html
    #         https://developer.android.com/ndk/guides/application_mk.html
    # if it makes sense for CMake, then replace LOCAL, APP, or NDK with ANDROID,
    # and we have that variable below.
    # The exception is ANDROID_TOOLCHAIN vs NDK_TOOLCHAIN_VERSION.
    # Since we only have one version of each gcc and clang, specifying a version
    # doesn't make much sense.
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_TOOLCHAIN=${ANDROID_TOOLCHAIN}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_ABI=${ANDROID_ABI}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_PLATFORM=${ANDROID_PLATFORM}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_STL=${ANDROID_STL}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_PIE=${ANDROID_PIE}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_CPP_FEATURES=${ANDROID_CPP_FEATURES}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_ALLOW_UNDEFINED_SYMBOLS=${ANDROID_ALLOW_UNDEFINED_SYMBOLS}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_ARM_MODE=${ANDROID_ARM_MODE}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_ARM_NEON=${ANDROID_ARM_NEON}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_DISABLE_NO_EXECUTE=${ANDROID_DISABLE_NO_EXECUTE}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_DISABLE_RELRO=${ANDROID_DISABLE_RELRO}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_DISABLE_FORMAT_STRING_CHECKS=${ANDROID_DISABLE_FORMAT_STRING_CHECKS}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_CCACHE=${ANDROID_CCACHE}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_UNIFIED_HEADERS=${ANDROID_UNIFIED_HEADERS}
    )

    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_SYSROOT_ABI=${ANDROID_SYSROOT_ABI} # arch
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_PLATFORM_LEVEL=${ANDROID_PLATFORM_LEVEL}
    )

    # Variables are only for compatibility.
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL}
    )
    list(APPEND bcm_CMAKE_ARGS
      -DANDROID_TOOLCHAIN_NAME=${ANDROID_TOOLCHAIN_NAME}
    )
  endif()
  
  
  #-----------------------------------------------------------------------
  # Args for bcm_boost_cmaker.
  #-----------------------------------------------------------------------

  # Download dir for boost sources.
  if(boost_VERSION)
    list(APPEND bcm_CMAKE_ARGS
      -Dboost_VERSION=${boost_VERSION}
    )
  endif()
  if(boost_COMPONENTS)
    list(APPEND bcm_CMAKE_ARGS
      -Dboost_COMPONENTS=${boost_COMPONENTS}
    )
  endif()
  if(bcm_DOWNLOAD_DIR)
    list(APPEND bcm_CMAKE_ARGS
      -Dbcm_DOWNLOAD_DIR=${bcm_DOWNLOAD_DIR}
    )
  endif()
  if(bcm_BUILD_TOOLS_ONLY)
    list(APPEND bcm_CMAKE_ARGS
      -Dbcm_BUILD_TOOLS_ONLY=${bcm_BUILD_TOOLS_ONLY}
    )
  endif()
  if(bcm_BUILD_BCP_TOOL)
    list(APPEND bcm_CMAKE_ARGS
      -Dbcm_BUILD_BCP_TOOL=${bcm_BUILD_BCP_TOOL}
    )
  endif()
  if(bcm_STATUS_DEBUG)
    list(APPEND bcm_CMAKE_ARGS
      -Dbcm_STATUS_DEBUG=${bcm_STATUS_DEBUG}
    )
  endif()
  if(bcm_STATUS_PRINT)
    list(APPEND bcm_CMAKE_ARGS
      -Dbcm_STATUS_PRINT=${bcm_STATUS_PRINT}
    )
  endif()
  

  #-----------------------------------------------------------------------
  # BUILDING
  #-----------------------------------------------------------------------

  # Configure boost libs
  file(MAKE_DIRECTORY ${bcm_bin_dir})
  execute_process(
    COMMAND
      ${CMAKE_COMMAND} ${bcm_SRC_DIR} ${bcm_CMAKE_ARGS}
    WORKING_DIRECTORY ${bcm_bin_dir}
  )
  
  # Build boost libs
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build .
    WORKING_DIRECTORY ${bcm_bin_dir}
  )


# TODO: http://stackoverflow.com/a/8200645
# To remove untracked files / directories do:
# git clean -fdx
# -f - force
# -d - directories too
# -x - remove ignored files too ( don't use this if you don't want to remove ignored files)
# Add -n to preview first so you don't accidentally remove stuff

endfunction()
