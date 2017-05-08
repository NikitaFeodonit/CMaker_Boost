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

# Based on the hunter,
# https://github.com/ruslo/hunter

# Copyright (c) 2017 Pawel Bylica
# All rights reserved.

include(bcm_internal_error)
include(bcm_status_debug)

function(bcm_get_lang_standard_flag LANG OUTPUT)
  set(CXX_standards 17 14 11 98)
  set(C_standards 11 99 90)
  # Find the <lang> standard flag.
  # This maps the logic in the CMake code:
  # https://github.com/Kitware/CMake/blob/3bccdd89c88864839a0c8d4ea56bd069c90fa02b/Source/cmLocalGenerator.cxx#L1433-L1467

  bcm_status_debug("CMAKE_${LANG}_STANDARD_DEFAULT: ${CMAKE_${LANG}_STANDARD_DEFAULT}")
  bcm_status_debug("CMAKE_${LANG}_STANDARD: ${CMAKE_${LANG}_STANDARD}")
  bcm_status_debug("CMAKE_${LANG}_EXTENSIONS: ${CMAKE_${LANG}_EXTENSIONS}")
  bcm_status_debug("CMAKE_${LANG}_STANDARD_REQUIRED: ${CMAKE_${LANG}_STANDARD_REQUIRED}")

  set("${OUTPUT}" "" PARENT_SCOPE)  # Reset output in case of quick return.

  string(COMPARE EQUAL "${CMAKE_${LANG}_STANDARD_DEFAULT}" "" no_default)
  if(no_default)
    # This compiler has no notion of language standard levels.
    # https://github.com/Kitware/CMake/blob/3bccdd89c88864839a0c8d4ea56bd069c90fa02b/Source/cmLocalGenerator.cxx#L1427-L1432
    bcm_status_debug("This compiler has no notion of language standard levels.")
    return()
  endif()

  set(standard "${CMAKE_${LANG}_STANDARD}")
  string(COMPARE EQUAL "${standard}" "" no_standard)
  if(no_standard)
    # The standard not defined by user.
    # https://github.com/Kitware/CMake/blob/3bccdd89c88864839a0c8d4ea56bd069c90fa02b/Source/cmLocalGenerator.cxx#L1433-L1437
    bcm_status_debug("The standard not defined by user.")
    return()
  endif()

  # Decide on version with extensions or a clean one.
  # By default extensions are assumed On.
  # https://github.com/Kitware/CMake/blob/3bccdd89c88864839a0c8d4ea56bd069c90fa02b/Source/cmLocalGenerator.cxx#L1438-L1446
  set(ext "EXTENSION")
  if(DEFINED CMAKE_${LANG}_EXTENSIONS AND NOT CMAKE_${LANG}_EXTENSIONS)
    set(ext "STANDARD")
  endif()

  set(standards "${${LANG}_standards}")
  list(FIND standards "${standard}" begin)
  if("${begin}" EQUAL "-1")
    bcm_internal_error("${LANG} standard ${standard} not known")
    return()
  endif()

  set(flag "")
  list(LENGTH standards end)
  math(EXPR end "${end} - 1")
  foreach(idx RANGE ${begin} ${end})
    list(GET standards ${idx} standard)
    set(option_name "CMAKE_${LANG}${standard}_${ext}_COMPILE_OPTION")
    set(flag "${${option_name}}")
    bcm_status_debug("${option_name}: '${flag}'")
    string(COMPARE NOTEQUAL "${flag}" "" has_flag)
    if(has_flag OR CMAKE_${LANG}_STANDARD_REQUIRED)
      # Break if flag found or standard is required and we don't want to
      # continue checking older standards.
      break()
    endif()
  endforeach()
  bcm_status_debug("bcm_get_lang_standard_flag(${LANG}): '${flag}'")
  set("${OUTPUT}" "${flag}" PARENT_SCOPE)
endfunction()
