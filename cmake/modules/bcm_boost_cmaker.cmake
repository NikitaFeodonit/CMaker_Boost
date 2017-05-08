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

# Based on the BoostBuilder,
# https://github.com/drbenmorgan/BoostBuilder
# Based on the build-boost.sh from CrystaX NDK, https://www.crystax.net/,
# https://github.com/crystax/android-platform-ndk/blob/master/build/tools/build-boost.sh
# Based on the hunter,
# https://github.com/ruslo/hunter

# CMake build/bundle script for Boost Libraries
# Automates build of Boost, allowing optional builds of library
# components plus CMake/pkg-config support files
#
# In current form, install Boost libraries in "tagged" layout so that
# Release/Debug/Profile Single/Multithread variants can be installed
# alongside each other. Fairly easy to modify to allow separation of these.

include(CMakeParseArguments) # cmake_parse_arguments
include(ExternalProject) # ExternalProject_Add, ExternalProject_Add_Step
include(GNUInstallDirs)
include(ProcessorCount) # ProcessorCount

include(bcm_check_boost_components)
include(bcm_fatal_error)
include(bcm_get_boost_download_params)
include(bcm_set_cmake_flags)
include(bcm_status_debug)

# To find bcm templates dir.
set(bcm_TEMPLATES_DIR "${CMAKE_CURRENT_LIST_DIR}")


# Useful vars:
# TODO: add more vars from FindBoost.cmake if necessary
#   Boost_USE_MULTITHREADED
#   Boost_USE_STATIC_LIBS
#   BUILD_SHARED_LIBS

#   bcm_STATUS_DEBUG
#   bcm_STATUS_PRINT

#   bcm_DOWNLOAD_DIR

#   bcm_BUILD_TOOLS_ONLY
#   bcm_BUILD_BCP_TOOL


# Function params:
#   VERSION "1.59.0"
#     Version of boost library.
#     Default is "1.64.0"
#   COMPONENTS regex filesystem
#     List libraries to build. Dependence libs will builded too.
#     By default will intalled only header lib.
#     May be "all" for build all boost libs,
#     in this case, there can be only one keyword "all".
#     The complete list of libraries provided by Boost can be found by
#     running the bootstrap.sh script supplied with Boost as:
#       ./bootstrap.sh --with-libraries=all --show-libraries
#
function(bcm_boost_cmaker)
  cmake_minimum_required(VERSION 3.2)

  cmake_parse_arguments(boost "" "VERSION" "COMPONENTS" "${ARGV}")
  # -> boost_VERSION
  # -> boost_COMPONENTS
  
  if(boost_UNPARSED_ARGUMENTS)
    bcm_fatal_error("Unparsed arguments: ${boost_UNPARSED_ARGUMENTS}")
  endif()
  if(NOT boost_VERSION)
    set(boost_VERSION "1.64.0")
  endif()
  if(NOT boost_COMPONENTS)
    set(boost_COMPONENTS "only_headers")
  endif()
  
  list(LENGTH boost_COMPONENTS components_length)
  list(FIND boost_COMPONENTS "all" all_index)
  if(NOT all_index EQUAL -1 AND NOT components_length EQUAL 1)
    bcm_fatal_error("COMPONENTS can not contain 'all' keyword with something others.")
  endif()

  bcm_check_boost_components(VERSION ${boost_VERSION} COMPONENTS ${boost_COMPONENTS})

  bcm_get_version_parts(${boost_VERSION}
      boost_MAJOR_VERSION boost_MINOR_VERSION boost_PATCH_VERSION boost_TWEAK_VERSION)

  bcm_get_boost_download_params(${boost_VERSION}
      boost_url boost_sha1 boost_src_dir_name boost_tar_file_name)

  if(NOT bcm_DOWNLOAD_DIR)
    set(bcm_DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR})
  endif()

  # TODO: set src dir from parent project
  set(boost_src_dir "${bcm_DOWNLOAD_DIR}/${boost_src_dir_name}"
    CACHE PATH "Directory to extract tar file with boost sources."
  )
  set(boost_tar_file "${bcm_DOWNLOAD_DIR}/${boost_tar_file_name}")


  #-----------------------------------------------------------------------
  # Compiler toolset.
  #-----------------------------------------------------------------------

  # http://stackoverflow.com/a/10055571
  if(ANDROID)
    set(toolset_name "${ANDROID_TOOLCHAIN}")
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    if(APPLE)
      set(toolset_name "darwin")
    else()
      set(toolset_name "gcc")
    endif()
  elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(toolset_name "clang")
#  elseif(CMAKE_CXX_COMPILER_ID MATCHES "Intel")
#    set(toolset_name "intel")
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
#  elseif(MSVC)
    set(toolset_name "msvc")
  elseif()
      bcm_fatal_error("Unsupported compiler system.")
  endif()

  if(ANDROID)
    set(toolset_version "ndk")
  else()
    set(toolset_version "")
  endif()

  set(toolset_full_name ${toolset_name})
  string(COMPARE NOTEQUAL "${toolset_version}" "" has_toolset_version)
  if(has_toolset_version)
    set(toolset_full_name ${toolset_name}-${toolset_version})
  endif()

  set(use_cmake_archiver TRUE)
  if(APPLE)
    # TODO: for both gcc and clang or only for gcc?
    # Using CMAKE_AR on OSX leads to error (b2 use 'libtool'):
    # * https://travis-ci.org/ingenue/bcm/jobs/204617507
    set(use_cmake_archiver FALSE)
  endif()
  
  if(MSVC)
    set(boost_compiler "${CMAKE_CXX_COMPILER}")
    string(REPLACE "/" "\\" boost_compiler "${boost_compiler}")
  else()
    set(boost_compiler "${CMAKE_CXX_COMPILER}")
  endif()

  # TODO: mpi
  set(using_mpi "")
  set(copy_mpi_command "")


  #-----------------------------------------------------------------------
  # Configure/build options
  #-----------------------------------------------------------------------

  set(bootstrap_args)
  set(common_b2_args)
  set(b2_args)
  set(bcp_b2_args)
  

  #-----------------------------------------------------------------------
  # common_b2_args
  #-----------------------------------------------------------------------
  
  list(APPEND common_b2_args "-a") # Rebuild everything
  list(APPEND common_b2_args "-q") # Stop at first error
  
  if(bcm_STATUS_DEBUG)
    list(APPEND common_b2_args "-d+2") # Show commands as they are executed
    list(APPEND common_b2_args "--debug-configuration") # Diagnose configuration
  else()
    list(APPEND common_b2_args "-d0") # Suppress all informational messages
  endif()
  
  # Parallelize build if possible
  ProcessorCount(NJOBS)
  if(NJOBS EQUAL 0)
    set(NJOBS 1)
  endif()
  list(APPEND common_b2_args "-j" "${NJOBS}")

  
  #-----------------------------------------------------------------------
  # b2_args
  #-----------------------------------------------------------------------

  list(APPEND b2_args "toolset=${toolset_full_name}")

  # Install headers and compiled library files
  # to the configured locations.
  list(APPEND b2_args "install")
  
  # Build and install only compiled library files to the stage directory.
  #list(APPEND b2_args "stage")
  # --stagedir=<STAGEDIR>   Install library files here


  #-----------------------------------------------------------------------
  # Directories
  #
  
  # Install architecture independent files here
  list(APPEND b2_args
    "--prefix=${CMAKE_INSTALL_PREFIX}"
  )
  # Install header files here
  list(APPEND b2_args
    "--includedir=${CMAKE_INSTALL_FULL_INCLUDEDIR}"
  )
  # Install library files here
  list(APPEND b2_args
    "--libdir=${CMAKE_INSTALL_FULL_LIBDIR}"
  )

  
  #-----------------------------------------------------------------------
  # Construct the final library list to install, with and without libs
  #

  # TODO: check for only one must be, with or without
  
  # Build and install the specified <library>. If this option is used,
  # only libraries specified using this option will be built.
  string(COMPARE EQUAL "${boost_COMPONENTS}" "only_headers" only_headers)
  string(COMPARE EQUAL "${boost_COMPONENTS}" "all" build_all_libs)
  if(NOT build_all_libs AND NOT only_headers)
    foreach(build_lib ${boost_COMPONENTS})
      list(APPEND b2_args "--with-${build_lib}")
    endforeach()
  endif()

  # Do not build, stage, or install the specified <library>.
  # By default, all libraries are built.
  # TODO: change bcm_NOT_BUILD_LIBRARIES to params NOT COMPONENTS
  if(only_headers AND bcm_NOT_BUILD_LIBRARIES)
    foreach(not_build_lib ${bcm_NOT_BUILD_LIBRARIES})
      list(APPEND b2_args "--without-${not_build_lib}")
    endforeach()
  endif()

  
  #-----------------------------------------------------------------------
  # Build variants
  #
  if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug"
      AND NOT CMAKE_BUILD_TYPE STREQUAL "Release")
    message(FATAL_ERROR "Not supported build type ${CMAKE_BUILD_TYPE}, only allowed Debug and Release.")
  endif()
  
  if(CMAKE_BUILD_TYPE STREQUAL "Release")
      list(APPEND b2_args "variant=release")
  elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
      list(APPEND b2_args "variant=debug")
  endif()
  
  if(BUILD_SHARED_LIBS AND Boost_USE_STATIC_LIBS)
    message(FATAL_ERROR "BUILD_SHARED_LIBS AND Boost_USE_STATIC_LIBS are both defined as ON")
  elseif(DEFINED BUILD_SHARED_LIBS AND NOT BUILD_SHARED_LIBS
        AND DEFINED Boost_USE_STATIC_LIBS AND NOT Boost_USE_STATIC_LIBS)
    message(FATAL_ERROR "BUILD_SHARED_LIBS AND Boost_USE_STATIC_LIBS are both defined as OFF")
  elseif(BUILD_SHARED_LIBS AND NOT Boost_USE_STATIC_LIBS)
    list(APPEND b2_args "link=shared")
    # TODO: for BOOST_ALL_DYN_LINK
    # see hunter/cmake/templates/BoostConfig.cmake.in
    # and hunter/cmake/find/FindBoost.cmake
    #if(MSVC)
    #  set(BOOST_ALL_DYN_LINK ON)
    #endif()
  elseif(NOT BUILD_SHARED_LIBS AND Boost_USE_STATIC_LIBS)
    # TODO: make only static - need correct detection in BoostConfig for FindBoost
    #list(APPEND b2_args "link=shared,static")
    list(APPEND b2_args "link=static")
  else() # both are NOT DEFINED
    list(APPEND b2_args "link=static")
  endif()
  
  option(Boost_USE_MULTITHREADED "Build Boost multi threaded library variants" ON)
  if(Boost_USE_MULTITHREADED)
    list(APPEND b2_args "threading=multi")
  else()
    # TODO: can we use olny static?
    #list(APPEND b2_args "threading=multi,single")
    list(APPEND b2_args "threading=single")
  endif()
  

  #-----------------------------------------------------------------------
  # OS specifits
  #

  if(ANDROID)
    # TODO: add work with ICU
    list(APPEND bcm_BOOTSTRAP_ARGS "--without-icu")
    
#    list(APPEND b2_args "--layout=system")
    list(APPEND b2_args "--layout=tagged")
    
    # Whether to link to static or shared C and C++ runtime.
    list(APPEND b2_args "runtime-link=shared")
    
    # Legal values for 'target-os':
    # "aix" "android" "appletv" "bsd" "cygwin" "darwin" "freebsd" "haiku" "hpux"
    # "iphone" "linux" "netbsd" "openbsd" "osf" "qnx" "qnxnto" "sgi" "solaris"
    # "unix" "unixware" "windows" "vms" "elf"
    list(APPEND b2_args "target-os=android")
    
    # Legal values for 'binary-format':
    # "elf" "mach-o" "pe" "xcoff"
    list(APPEND b2_args "binary-format=elf")
    
    
    # Legal values for 'architecture':
    # "x86" "ia64" "sparc" "power"
    # "mips1" "mips2" "mips3" "mips4" "mips32" "mips32r2" "mips64"
    # "parisc" "arm" "combined" "combined-x86-power"
    #
    # Legal values for 'abi':
    # "aapcs" "eabi" "ms" "n32" "n64" "o32" "o64" "sysv" "x32"
    if(ANDROID_SYSROOT_ABI STREQUAL arm
        OR ANDROID_SYSROOT_ABI STREQUAL arm64)
      set(bcm_BJAM_ARCH arm)
      set(bcm_BJAM_ABI aapcs)
    elseif(ANDROID_SYSROOT_ABI STREQUAL x86
        OR ANDROID_SYSROOT_ABI STREQUAL x86_64)
      set(bcm_BJAM_ARCH x86)
      set(bcm_BJAM_ABI sysv)
    elseif(ANDROID_SYSROOT_ABI STREQUAL mips)
      set(bcm_BJAM_ARCH mips1)
      set(bcm_BJAM_ABI o32)
    elseif(ANDROID_SYSROOT_ABI STREQUAL mips64)
      set(bcm_BJAM_ARCH mips1)
      set(bcm_BJAM_ABI o64)
    endif()
    
    # Legal values for 'address-model':
    # "16" "32" "64" "32_64"
    if(ANDROID_SYSROOT_ABI MATCHES "^.{3,4}64$")
      set(bcm_BJAM_ADDR_MODEL 64)
    else()
      set(bcm_BJAM_ADDR_MODEL 32)
    endif()
    
    list(APPEND b2_args "address-model=${bcm_BJAM_ADDR_MODEL}")
    list(APPEND b2_args "architecture=${bcm_BJAM_ARCH}")
    list(APPEND b2_args "abi=${bcm_BJAM_ABI}")
  endif()


  if(APPLE OR MSVC OR (UNIX AND NOT ANDROID))
    # TODO: address-model=64 for MSVC and amd64
    #string(COMPARE EQUAL "${bcm_MSVC_ARCH}" "amd64" is_x64)
    #if(MSVC AND is_x64)
    #  list(APPEND b2_args "address-model=64")
    #endif()

    list(APPEND b2_args "--layout=tagged")
  endif()



  #-----------------------------------------------------------------------
  # Compiler and linker flags
  #
  
  bcm_set_cmake_flags()
  # -> CMAKE_C_FLAGS
  # -> CMAKE_CXX_FLAGS

  if(MSVC)
    # Disable auto-linking
    # TODO: check with BOOST_ALL_DYN_LINK == OFF
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /DBOOST_ALL_NO_LIB=1")
  
    # Fix some compile errors
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /DNOMINMAX")
  
    # Fix boost.python:
    # include\pymath.h: warning C4273: 'round': inconsistent dll linkage
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /DHAVE_ROUND")
  endif()

  string(COMPARE NOTEQUAL "${CMAKE_OSX_SYSROOT}" "" have_osx_sysroot)
  if(have_osx_sysroot)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -isysroot ${CMAKE_OSX_SYSROOT}")
  endif()


  # Need to find out how to add flags on a per variant mode
  # ... e.g. "gdwarf" etc as per
  # https://cdcvs.fnal.gov/redmine/projects/build-framework/repository/boost-ssi-build/revisions/master/entry/build_boost.sh
  
  # TODO: to bcm_set_cmake_flags()
  if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(CMAKE_C_FLAGS
      "${CMAKE_C_FLAGS_RELEASE} ${CMAKE_C_FLAGS}"
    )
    set(CMAKE_CXX_FLAGS
      "${CMAKE_CXX_FLAGS_RELEASE} ${CMAKE_CXX_FLAGS}"
    )
  elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_C_FLAGS
      "${CMAKE_C_FLAGS_DEBUG} ${CMAKE_C_FLAGS}"
    )
    set(CMAKE_CXX_FLAGS
      "${CMAKE_CXX_FLAGS_DEBUG} ${CMAKE_CXX_FLAGS}"
    )
  endif()
  
#  if(BUILD_SHARED_LIBS)
#    set(bcm_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
#  elseif()
#    set(bcm_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS}")
#  endif()
  
  if(BUILD_SHARED_LIBS AND CMAKE_EXE_LINKER_FLAGS)
    list(APPEND b2_args "linkflags=${CMAKE_EXE_LINKER_FLAGS}")
  endif()


  #-----------------------------------------------------------------------
  # user-config.jam file.
  #
  set(user_config_jamfile "${PROJECT_BINARY_DIR}/user-config.jam")

  file(
      WRITE ${user_config_jamfile}
      "using ${toolset_name}\n"
      "  : ${toolset_version}\n"
  )
  
  if(MSVC)
    # For Visual Studio C++ flags must not be set in compiler section.
    # Section <compileflags> should be used.
    #   * https://github.com/ruslo/hunter/issues/179
    file(
        APPEND ${user_config_jamfile}
        "  : \"${boost_compiler}\"\n"
    )
  else()
    # For Android C++ flags must be part of the compiler section:
    #   * https://github.com/ruslo/hunter/issues/174
    # For 'sanitize-address' toolchain flags must be part of the compiler section:
    #   * https://github.com/ruslo/hunter/issues/269
    file(
        APPEND ${user_config_jamfile}
        "  : \"${boost_compiler}\" ${CMAKE_CXX_FLAGS}\n"
    )
  endif()
  
  if(use_cmake_archiver)
    # We need custom '<archiver>' and '<ranlib>' for
    # Android LTO ('*-gcc-ar' instead of '*-ar')
    # WARNING: no spaces between '<archiver>' and '${CMAKE_AR}'!
    file(
        APPEND ${user_config_jamfile}
        "  : <archiver>\"${CMAKE_AR}\"\n"
        " <ranlib>\"${CMAKE_RANLIB}\"\n"
    )
  endif()

  if(MSVC)
    # See 'boost_compiler' section
    string(REPLACE " " ";" cxx_flags_list "${CMAKE_CXX_FLAGS}")
    foreach(cxx_flag ${cxx_flags_list})
      file(
          APPEND ${user_config_jamfile}
          "  <compileflags>${cxx_flag}\n"
      )
    endforeach()
  endif()

  file(
      APPEND ${user_config_jamfile}
      ";\n"
      "${using_mpi}\n"
  )

  list(APPEND b2_args "--user-config=${user_config_jamfile}")





  if(MSVC)
    # TODO: env_cmd for MSVC
    #set(env_cmd "${bcm_MSVC_VCVARSALL}" "${bcm_MSVC_ARCH}")
  else()
    # Workaround for: http://public.kitware.com/Bug/view.php?id=15567
    set(env_cmd "${CMAKE_COMMAND}" -E echo "configure")
  endif()

  if(MSVC)
    # Logging as Workaround for VS_UNICODE_OUTPUT issue:
    # https://public.kitware.com/Bug/view.php?id=14266
    set(log_opts LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
    set(step_log_opts LOG 1)
    get_filename_component(x "@bcm_PACKAGE_SOURCE_DIR@/.." ABSOLUTE)
    bcm_status_print(
        "For progress check log files in directory: ${boost_src_dir}"
    )
  else()
    set(log_opts "")
    set(step_log_opts "")
  endif()



  # TODO: cmd for MINGW
#  if(MSVC)
#    set(bootstrap_cmd "bootstrap.bat")
#    set(b2_cmd "b2")
#  elseif(MINGW)
#    set(bootstrap_cmd "bootstrap.bat" "gcc")
#    set(b2_cmd "b2")
#  else()
#    set(bootstrap_cmd "./bootstrap.sh")
#    set(b2_cmd "./b2")
#  endif()


  
  
  #-----------------------------------------------------------------------
  # Build Boost
  #-----------------------------------------------------------------------

  #-----------------------------------------------------------------------
  # Download tar file
  #
  if(NOT EXISTS "${boost_tar_file}")
    message(STATUS "Download ${boost_url}")
    file(
      DOWNLOAD "${boost_url}" "${boost_tar_file}"
      EXPECTED_HASH SHA1=${boost_sha1}
      SHOW_PROGRESS
    )
  endif()

  
  #-----------------------------------------------------------------------
  # Extract tar file
  #
  if(NOT EXISTS "${boost_src_dir}")
    message(STATUS "Extract ${boost_tar_file}")
    file(MAKE_DIRECTORY ${boost_src_dir})
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xjf ${boost_tar_file}
      WORKING_DIRECTORY ${bcm_DOWNLOAD_DIR}
    )
  endif()
  
  
  # TODO: Copy source tree to build dir and build with copy.
  
  #-----------------------------------------------------------------------
  # Set build parameters and steps
  #
  ExternalProject_Add(boost
    SOURCE_DIR
      ${boost_src_dir}
    BUILD_IN_SOURCE
      1
    CONFIGURE_COMMAND
      ""
#      ${env_cmd}
    BUILD_COMMAND
      ""
    INSTALL_COMMAND
      ""
    STEP_TARGETS
      configure install
#    ${log_opts}
  )

  
  #-----------------------------------------------------------------------
  # Build b2 (bjam) if required.
  #
  unset(b2_file CACHE)
  find_program(b2_file NAMES b2 PATHS ${boost_src_dir} NO_DEFAULT_PATH)
  if(NOT b2_file)

    if(bcm_STATUS_DEBUG)
      bcm_status_debug("Options for b2 (bjam) tool building:")
      foreach(opt ${bootstrap_args})
        bcm_status_debug("  ${opt}")
      endforeach()
      bcm_status_debug("------")
    endif()

    ExternalProject_Add_Step(boost boost_build_b2
      COMMENT
        "Build b2 (bjam) tool."
      COMMAND
        <SOURCE_DIR>/bootstrap.sh ${bootstrap_args}
      DEPENDERS
        configure
      WORKING_DIRECTORY
        <BINARY_DIR>
#      ${step_log_opts}
    )
  endif()

  
  #-----------------------------------------------------------------------
  # Build and install bcp program if required.
  #
  if(bcm_BUILD_BCP_TOOL)
    unset(bcp_file CACHE)
    find_program(bcp_file NAMES bcp PATHS ${CMAKE_INSTALL_FULL_BINDIR}/bcp NO_DEFAULT_PATH)

    if(NOT bcp_file)
      # We need to use a custom set of layout and toolset arguments
      # to prevent "duplicate target" errors.
      list(APPEND bcp_b2_args ${common_b2_args})

      if(bcm_STATUS_DEBUG)
        bcm_status_debug("Options for bcp tool building:")
        foreach(opt ${bcp_b2_args})
          bcm_status_debug("  ${opt}")
        endforeach()
        bcm_status_debug("------")
      endif()

      ExternalProject_Add_Step(boost install_bcp
        COMMENT
          "Build bcp tool."
        COMMAND
          <BINARY_DIR>/b2 ${bcp_b2_args} <SOURCE_DIR>/tools/bcp
        COMMAND
          ${CMAKE_COMMAND} -E copy <BINARY_DIR>/dist/bin/bcp ${CMAKE_INSTALL_FULL_BINDIR}/bcp
        DEPENDS
          ${boost_src_dir}/b2
        DEPENDEES
          install
        WORKING_DIRECTORY
          <BINARY_DIR>
#        ${step_log_opts}
      )
    endif()
  endif()

  
  #-----------------------------------------------------------------------
  # Exit if build tools only.
  #
  if(bcm_BUILD_TOOLS_ONLY)
    return()
  endif()


  #-----------------------------------------------------------------------
  # Build boost library
  #
  list(APPEND b2_args ${common_b2_args})

  if(bcm_STATUS_DEBUG)
    file(READ "${user_config_jamfile}" USER_JAM_CONTENT)
    bcm_status_debug("Options for boost library building:")
    foreach(opt ${b2_args})
      bcm_status_debug("  ${opt}")
    endforeach()
    bcm_status_debug("------")
    bcm_status_debug("Boost user jam config:")
    bcm_status_debug("------\n${USER_JAM_CONTENT}")
    bcm_status_debug("------")
  endif()

  ExternalProject_Add_Step(boost boost_build_libs
    COMMENT
      "Build boost library."
    COMMAND
      <BINARY_DIR>/b2 ${b2_args}
    DEPENDS
      ${boost_src_dir}/b2
    DEPENDEES
      configure
    DEPENDERS
      install
    WORKING_DIRECTORY
      <BINARY_DIR>
#    ${step_log_opts}
  )

  #-----------------------------------------------------------------------
  # Create and install CMake support files.
  #
  # This uses a CMake script run at install time to do the heavy
  # lifting of discovery of installed Boost libraries and setting
  # up appropriate import targets for them.
  set(cmake_support_files_install_dir
    "${CMAKE_INSTALL_FULL_LIBDIR}/cmake/Boost-${boost_VERSION}"
  )
  
  configure_file(
    ${bcm_TEMPLATES_DIR}/BoostWriteCMakeImportFiles.cmake.in
    ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
    @ONLY
  )
  
  configure_file(
    ${bcm_TEMPLATES_DIR}/BoostConfigVersion.cmake.in
    ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake
    @ONLY
  )
  
  configure_file(
    ${bcm_TEMPLATES_DIR}/BoostConfig.cmake.in
    ${PROJECT_BINARY_DIR}/BoostConfig.cmake
    @ONLY
  )
  
  # Step for installation of all the above, as required
  ExternalProject_Add_Step(boost install_cmake_support_files
    COMMAND
      ${CMAKE_COMMAND} -E make_directory ${cmake_support_files_install_dir}
    COMMAND
      ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
    COMMAND
      ${CMAKE_COMMAND} -E copy
        ${PROJECT_BINARY_DIR}/BoostConfig.cmake ${cmake_support_files_install_dir}
    COMMAND
      ${CMAKE_COMMAND} -E copy
        ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake ${cmake_support_files_install_dir}
    DEPENDEES
      install
    DEPENDS
      ${bcm_TEMPLATES_DIR}/BoostLibraryDepends.cmake.in
      ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
      ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake
      ${PROJECT_BINARY_DIR}/BoostConfig.cmake
#    ${step_log_opts}
  )
endfunction()
