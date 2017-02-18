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

cmake_minimum_required(VERSION 3.2 FATAL_ERROR)

project(test_compile_with_boost CXX)

# Make compile, build and install the boost at a config CMake phase,
# generate the config file BoostConfig.
# TODO: set vars before boost_cmaker()
include(${PROJECT_SOURCE_DIR}/cmake/BoostCMaker/BoostCMaker.cmake)
boost_cmaker()

# Set CMake's search path for the config file BoostConfig.
set(CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})

# Use newly got boost library.
set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_DEBUG_RUNTIME OFF)
find_package(Boost 1.63 REQUIRED COMPONENTS filesystem system)

# QUIET suppresses the big warning issued, and allows fallback
#find_package(Boost 1.63 QUIET CONFIG COMPONENTS filesystem system)
#if(NOT Boost_FOUND)
    # Do warn about falling back to system, but can make message more
    # explicit/informative
#    message(STATUS "No BoostConfig.cmake config file found, falling back to FindBoost...")
    # Use REQUIRED flag to fail if not found
#    find_package(Boost 1.63 REQUIRED COMPONENTS filesystem system)
#endif()

# test executables
add_executable (${PROJECT_NAME} test_header.cpp)
set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD 11)

add_executable (${PROJECT_NAME}_2 test_compiled.cpp)
target_link_libraries(${PROJECT_NAME}_2 ${Boost_LIBRARIES})
set_property(TARGET ${PROJECT_NAME}_2 PROPERTY CXX_STANDARD 11)

# Use/Link it to a boost library, BoostBuilder sets the same variables
# to libs as FindBoost does, but these are imported targets so
#  always expand to the exact library used
#target_include_directories(${PROJECT_NAME}_2 PRIVATE ${Boost_INCLUDE_DIRS})
#target_link_libraries(${PROJECT_NAME}_2
#    PRIVATE ${Boost_SYSTEM_LIBRARY} ${Boost_FILESYSTEM_LIBRARY}
#)
