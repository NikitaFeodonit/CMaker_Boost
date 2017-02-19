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

# Based on the CMakeLists.txt from BoostBuilder
# https://github.com/drbenmorgan/BoostBuilder


# CMake build/bundle script for Boost Libraries
# Automates build of Boost, allowing optional builds of library
# components plus CMake/pkg-config support files
#
# In current form, install Boost libraries in "tagged" layout so that
# Release/Debug/Profile Single/Multithread variants can be installed
# alongside each other. Fairly easy to modify to allow separation of
# these.


cmake_minimum_required(VERSION 3.2)
project(BoostCMakerInternal)

set(BB_SRC_DIR "${PROJECT_SOURCE_DIR}/BoostBuilder")


#-----------------------------------------------------------------------
# CORE CONFIGURE/BUILD OPTIONS
#-----------------------------------------------------------------------

# CMake utilities
include(${BB_SRC_DIR}/BoostBuildUtility.cmake)
include(GNUInstallDirs)

# Basic Boost Parameters
set(Boost_MAJOR_VERSION 1)
set(Boost_MINOR_VERSION 63)
set(Boost_SUBMINOR_VERSION 0)
set(Boost_VERSION
  "${Boost_MAJOR_VERSION}.${Boost_MINOR_VERSION}.${Boost_SUBMINOR_VERSION}"
)
set(Boost_VERSION_UNDERSCORE
  "${Boost_MAJOR_VERSION}_${Boost_MINOR_VERSION}_${Boost_SUBMINOR_VERSION}"
)
set(Boost_VERSION_SHA1
  "9f1dd4fa364a3e3156a77dc17aa562ef06404ff6"
)

set(Boost_BOOTSTRAP_ARGS)
set(Boost_B2_ARGS)
set(Boost_B2_BCP_ARGS)
set(Boost_BUILD_ARGS)

#-----------------------------------------------------------------------
# VARIANTS
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# - Threading model
option(boost.singlethread "Build Boost single threaded library variants" OFF)
if(boost.singlethread)
  list(APPEND Boost_BUILD_ARGS "threading=multi,single")
else()
  list(APPEND Boost_BUILD_ARGS "threading=multi")
endif()

#-----------------------------------------------------------------------
# - Static libraries
option(boost.staticlibs "Build Boost static library variants" OFF)
if(boost.staticlibs)
  list(APPEND Boost_BUILD_ARGS "link=shared,static")
else()
  list(APPEND Boost_BUILD_ARGS "link=shared")
endif()

#if(BUILD_SHARED_LIBS)
#  list(APPEND Boost_BUILD_ARGS "link=shared")
#else()
#  list(APPEND Boost_BUILD_ARGS "link=shared,static")
#endif()

#-----------------------------------------------------------------------
# - Release/Debug/Profile libraries
# NB... To support profile libs, need to patch Boost's
# tools/build/src/tools/common.jam
# to add an entry in `local rule runtime-tag` to add a letter
# tag for profiling. Not yet clear if this rule can be overidden
# without patching
set(__boost.buildmodes "variant=release")

option(boost.debuglibs "Build Boost debug library variants" OFF)
if(boost.debuglibs)
  set(__boost.buildmodes "${__boost.buildmodes},debug")
endif()

#option(boost.profilelibs "Build boost profile library variants" OFF)
#if(boost.profilelibs)
#  set(__boost.buildmodes "${__boost.buildmodes},profile")
#endif()

list(APPEND Boost_BUILD_ARGS "${__boost.buildmodes}")

#if(CMAKE_BUILD_TYPE STREQUAL "Release")
#    list(APPEND Boost_BUILD_ARGS "variant=release")
#elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
#    list(APPEND Boost_BUILD_ARGS "variant=debug")
#endif()

#-----------------------------------------------------------------------
# - Prebuild setup
# Determine the toolset in use by CMake and create needed configure/build
# arguments and custom user-config.jam file as needed
include(${BB_SRC_DIR}/BoostToolsetId.cmake)
Boost_Get_ToolsetId(_boost_toolset)

set(Boost_BUILD_C_FLAGS   "${CMAKE_C_FLAGS}")
set(Boost_BUILD_CXX_FLAGS "${CMAKE_CXX_FLAGS}")

# TODO: detect build type, release or debug, for any value in CMAKE_BUILD_TYPE
if(CMAKE_BUILD_TYPE STREQUAL "Release")
  set(Boost_BUILD_C_FLAGS
    "${CMAKE_C_FLAGS_RELEASE} ${Boost_BUILD_C_FLAGS}"
  )
  set(Boost_BUILD_CXX_FLAGS
    "${CMAKE_CXX_FLAGS_RELEASE} ${Boost_BUILD_CXX_FLAGS}"
  )
elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(Boost_BUILD_C_FLAGS
    "${CMAKE_C_FLAGS_DEBUG} ${Boost_BUILD_C_FLAGS}"
  )
  set(Boost_BUILD_CXX_FLAGS
    "${CMAKE_CXX_FLAGS_DEBUG} ${Boost_BUILD_CXX_FLAGS}"
  )
endif()

# Need to find out how to add flags on a per variant mode
# ... e.g. "gdwarf" etc as per
#https://cdcvs.fnal.gov/redmine/projects/build-framework/repository/boost-ssi-build/revisions/master/entry/build_boost.sh

# For GCC/Clang (could also add logic for 1y/14)
set(Boost_BUILD_CXX_STANDARD_FLAGS "-std=c++11")

# For Apple, though Mavericks onwards should default to libc++
if(CMAKE_COMPILER_ID STREQUAL "AppleClang")
  set(Boost_BUILD_CXX_STANDARD_FLAGS
    "${Boost_BUILD_CXX_STANDARD_FLAGS} -stdlib=libc++"
  )
endif()

set(Boost_BUILD_CXX_FLAGS
  "${Boost_BUILD_CXX_STANDARD_FLAGS} ${Boost_BUILD_CXX_FLAGS}"
)

if(BUILD_SHARED_LIBS)
  set(Boost_BUILD_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
elseif()
  set(Boost_BUILD_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS}")
endif()

if(_boost_toolset)
  list(APPEND Boost_BOOTSTRAP_ARGS "toolset=${_boost_toolset}")
  list(APPEND Boost_BUILD_ARGS "toolset=${_boost_toolset}")

  set(Boost_USER_CONFIG_CONTEXT "
    using ${_boost_toolset} :
    :
    ${CMAKE_CXX_COMPILER} :
    "
  )
  if(Boost_BUILD_C_FLAGS)
    string(APPEND Boost_USER_CONFIG_CONTEXT "
      <cflags>    \"${Boost_BUILD_C_FLAGS}\""
    )
  endif()
  if(Boost_BUILD_CXX_FLAGS)
    string(APPEND Boost_USER_CONFIG_CONTEXT "
      <cxxflags>  \"${Boost_BUILD_CXX_FLAGS}\""
    )
  endif()
  if(Boost_BUILD_LINKER_FLAGS)
    string(APPEND Boost_USER_CONFIG_CONTEXT "
      <linkflags> \"${Boost_BUILD_LINKER_FLAGS}\""
    )
  endif()
  # We must escape ";"
  string(APPEND Boost_USER_CONFIG_CONTEXT "
    \;
    "
  )

  set(Boost_USER_CONFIG_JAMFILE "${PROJECT_BINARY_DIR}/user-config.jam")
  file(WRITE "${Boost_USER_CONFIG_JAMFILE}" ${Boost_USER_CONFIG_CONTEXT})

  set(Boost_BUILD_USER_CONFIG_ARGS
    "--user-config=${Boost_USER_CONFIG_JAMFILE}"
  )
  list(APPEND Boost_BUILD_ARGS "${Boost_BUILD_USER_CONFIG_ARGS}")
endif()

# Construct the final library list to install
string(REPLACE ";" "," Boost_WITHLIBRARY_LIST ${Boost_BUILD_LIBRARIES})

list(APPEND Boost_BOOTSTRAP_ARGS "--with-libraries=${Boost_WITHLIBRARY_LIST}")

# Parallelize build if possible
include(ProcessorCount)
ProcessorCount(NJOBS)
if(NJOBS EQUAL 0)
  set(NJOBS 1)
endif()

#-----------------------------------------------------------------------
# Build Boost
#

if(NOT Boost_DOWNLOAD_DIR)
  set(Boost_DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR})
endif()

set(Boost_SRC_DIR_NAME "boost_${Boost_VERSION_UNDERSCORE}")
set(Boost_SRC_DIR "${Boost_DOWNLOAD_DIR}/${Boost_SRC_DIR_NAME}"
  CACHE PATH "Directory to extract tar file with boost sources."
)
set(Boost_TAR_FILE_NAME "${Boost_SRC_DIR_NAME}.tar.bz2")
set(Boost_TAR_FILE "${Boost_DOWNLOAD_DIR}/${Boost_TAR_FILE_NAME}")
set(Boost_URL
  "https://downloads.sourceforge.net/project/boost/boost/${Boost_VERSION}/${Boost_TAR_FILE_NAME}"
)

if(NOT EXISTS "${Boost_TAR_FILE}")
  message(STATUS "Download ${Boost_URL}")
  file(
    DOWNLOAD "${Boost_URL}" "${Boost_TAR_FILE}"
    EXPECTED_HASH SHA1=${Boost_VERSION_SHA1}
    SHOW_PROGRESS
  )
endif()

if(NOT EXISTS "${Boost_SRC_DIR}")
  message(STATUS "Extract ${Boost_TAR_FILE}")
  file(MAKE_DIRECTORY ${Boost_SRC_DIR})
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xjf ${Boost_TAR_FILE}
    WORKING_DIRECTORY ${Boost_DOWNLOAD_DIR}
  )
endif()


list(APPEND Boost_B2_ARGS -q -j${NJOBS} install)
list(APPEND Boost_B2_ARGS --layout=tagged)
list(APPEND Boost_B2_ARGS --debug-configuration)

if(Boost_BUILD_VERBOSE)
  list(APPEND Boost_B2_ARGS -d2)
else()
  list(APPEND Boost_B2_ARGS -d0)
endif()


# Build b2 (bjam) if required
unset(b2Path CACHE)
find_program(b2Path NAMES b2 PATHS ${Boost_SRC_DIR} NO_DEFAULT_PATH)

# TODO: Copy source tree to build dir and build with copy.

include(ExternalProject)

if(NOT b2Path)
  ExternalProject_Add(boost
    SOURCE_DIR
      ${Boost_SRC_DIR}
    BUILD_IN_SOURCE
      1
    CONFIGURE_COMMAND
      <SOURCE_DIR>/bootstrap.sh
      --prefix=${CMAKE_INSTALL_PREFIX}
      --includedir=${CMAKE_INSTALL_FULL_INCDIR}
      --libdir=${CMAKE_INSTALL_FULL_LIBDIR}
      ${Boost_BOOTSTRAP_ARGS}
    # All in one build/install step is slightly faster
    BUILD_COMMAND
      ""
    INSTALL_COMMAND
      ./b2 ${Boost_B2_ARGS} ${Boost_BUILD_ARGS}
    STEP_TARGETS
      configure install
  )

elseif(b2Path)
  ExternalProject_Add(boost
    SOURCE_DIR
      ${Boost_SRC_DIR}
    BUILD_IN_SOURCE
      1
    CONFIGURE_COMMAND
      ""
    # All in one build/install step is slightly faster
    BUILD_COMMAND
      ""
    INSTALL_COMMAND
      ./b2 ${Boost_B2_ARGS} ${Boost_BUILD_ARGS}
    STEP_TARGETS
      configure install
  )
endif()


#-----------------------------------------------------------------------
# Custom step to build and install the bcp program
# We need to use a custom set of layout and toolset arguments to
# prevent "duplicate target" errors.
#
list(APPEND Boost_B2_BCP_ARGS -q -j${NJOBS})

if(Boost_BUILD_VERBOSE)
  list(APPEND Boost_B2_BCP_ARGS -d2)
else()
  list(APPEND Boost_B2_BCP_ARGS -d0)
endif()

ExternalProject_Add_Step(boost install_bcp
  COMMAND
    ./b2 ${Boost_B2_BCP_ARGS}
    ${Boost_BUILD_USER_CONFIG_ARGS}
    ./tools/bcp
  COMMAND
    ${CMAKE_COMMAND} -E copy ./dist/bin/bcp ${CMAKE_INSTALL_FULL_BINDIR}/bcp
  DEPENDEES
    install
  WORKING_DIRECTORY
    <BINARY_DIR>
)


#-----------------------------------------------------------------------
# Create and install CMake support files.
# This uses a CMake script run at install time to do the heavy
# lifting of discovery of installed Boost libraries and setting
# up appropriate import targets for them.
#
set(Boost_INSTALL_CMAKEDIR
  "${CMAKE_INSTALL_FULL_LIBDIR}/cmake/Boost-${Boost_VERSION}"
)

configure_file(
  ${PROJECT_SOURCE_DIR}/BoostWriteCMakeImportFiles.cmake.in
  ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
  @ONLY
)

configure_file(
  ${BB_SRC_DIR}/BoostConfigVersion.cmake.in
  ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake
  @ONLY
)

configure_file(
  ${BB_SRC_DIR}/BoostConfig.cmake.in
  ${PROJECT_BINARY_DIR}/BoostConfig.cmake
  @ONLY
)

# Step for installation of all the above, as required
ExternalProject_Add_Step(boost install_cmake
  COMMAND
    ${CMAKE_COMMAND} -E make_directory ${Boost_INSTALL_CMAKEDIR}
  COMMAND
    ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
  COMMAND
    ${CMAKE_COMMAND} -E copy
      ${PROJECT_BINARY_DIR}/BoostConfig.cmake ${Boost_INSTALL_CMAKEDIR}
  COMMAND
    ${CMAKE_COMMAND} -E copy
      ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake ${Boost_INSTALL_CMAKEDIR}
  DEPENDEES
    install
  DEPENDS
    ${BB_SRC_DIR}/BoostLibraryDepends.cmake.in
    ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
    ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake
    ${PROJECT_BINARY_DIR}/BoostConfig.cmake
)
