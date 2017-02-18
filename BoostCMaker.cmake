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

# to find BoostCMakerInternal dir
set(BCM_SRC_DIR ${CMAKE_CURRENT_LIST_DIR})

function(boost_cmaker)
  cmake_minimum_required(VERSION 3.2)
  
  # BCM_COMMON_CMAKE_ARGS
  if(SUPRESS_VERBOSE_OUTPUT)
    list(APPEND BCM_COMMON_CMAKE_ARGS
      -DSUPRESS_VERBOSE_OUTPUT=${SUPRESS_VERBOSE_OUTPUT}
    )
  endif()
  if(CMAKE_INSTALL_PREFIX)
    list(APPEND BCM_COMMON_CMAKE_ARGS
      -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    )
  endif()
  if(CMAKE_BUILD_TYPE)
    list(APPEND BCM_COMMON_CMAKE_ARGS
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    )
  endif()
  if(BUILD_SHARED_LIBS)
    list(APPEND BCM_COMMON_CMAKE_ARGS
      -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
    )
  endif()
  
  
  # BCM_LIBS_CMAKE_ARGS
  if(CMAKE_TOOLCHAIN_FILE)
    list(APPEND BCM_LIBS_CMAKE_ARGS
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    )
  endif()
  if(CMAKE_GENERATOR)
    list(APPEND BCM_LIBS_CMAKE_ARGS
      -G "${CMAKE_GENERATOR}"
    )
  endif()
  if(CMAKE_MAKE_PROGRAM)
    list(APPEND BCM_LIBS_CMAKE_ARGS
      -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
    )
  endif()
  
  
  # List libraries to build. Dependence libs will builded too.
  # The complete list of libraries provided by Boost can be found by
  # running the bootstrap.sh script supplied with Boost as:
  #  ./bootstrap.sh --with-libraries=all --show-libraries
  set(Boost_BUILD_LIBRARIES
    filesystem
  )
  
  list(APPEND BCM_COMMON_CMAKE_ARGS
    -DBoost_BUILD_LIBRARIES=${Boost_BUILD_LIBRARIES}
  )
  
  # Download dir for boost sources
  # TODO: receive from external project too
  list(APPEND BCM_COMMON_CMAKE_ARGS
    -DBoost_DOWNLOAD_DIR=${PROJECT_BINARY_DIR}
  )
  
  # Configure boost libs
  list(APPEND BCM_LIBS_CMAKE_ARGS
    -Dboost.staticlibs=ON
  )
  list(APPEND BCM_LIBS_CMAKE_ARGS
    ${BCM_COMMON_CMAKE_ARGS}
  )
  
  set(BCMI_DIR_NAME "BoostCMakerInternal")
  set(BCMI_SRC_DIR  "${BCM_SRC_DIR}/${BCMI_DIR_NAME}")
  set(BCMI_WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/${BCMI_DIR_NAME}")

  file(MAKE_DIRECTORY ${BCMI_WORK_DIR})
  execute_process(
    COMMAND
      ${CMAKE_COMMAND} ${BCMI_SRC_DIR} ${BCM_LIBS_CMAKE_ARGS}
    WORKING_DIRECTORY ${BCMI_WORK_DIR}
  )
  
  # Build boost libs
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build .
    WORKING_DIRECTORY ${BCMI_WORK_DIR}
  )


# TODO: http://stackoverflow.com/a/8200645
# To remove untracked files / directories do:
# git clean -fdx
# -f - force
# -d - directories too
# -x - remove ignored files too ( don't use this if you don't want to remove ignored files)
# Add -n to preview first so you don't accidentally remove stuff

endfunction()
