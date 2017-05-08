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

# Can be used as separate project for boost building with standard CMake way.

cmake_minimum_required(VERSION 3.2)
project(BoostCMaker)

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/modules")

include(bcm_boost_cmaker)

if(NOT DEFINED boost_VERSION)
  set(default_boost_version ON)
endif()
if(NOT DEFINED boost_COMPONENTS)
  set(only_headers ON)
else()
  separate_arguments(boost_COMPONENTS)
endif()

if(default_boost_version AND only_headers)
  bcm_boost_cmaker()
elseif(default_boost_version)
  bcm_boost_cmaker(COMPONENTS ${boost_COMPONENTS})
elseif(only_headers)
  bcm_boost_cmaker(VERSION ${boost_VERSION})
else()
  bcm_boost_cmaker(VERSION ${boost_VERSION} COMPONENTS ${boost_COMPONENTS})
endif()
