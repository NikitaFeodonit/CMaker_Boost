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

include(bcm_fatal_error)

function(bcm_get_version_parts version out_major out_minor out_patch out_tweak)
  set(version_regex "^[0-9]+(\\.[0-9]+)?(\\.[0-9]+)?(\\.[0-9]+)?$")
  set(version_regex_1 "^[0-9]+$")
  set(version_regex_2 "^[0-9]+\\.[0-9]+$")
  set(version_regex_3 "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  set(version_regex_4 "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$")

  if(NOT version MATCHES ${version_regex})
    bcm_fatal_error("Problem parsing version string.")
  endif()

  if(version MATCHES ${version_regex_1})
    set(count 1)
  elseif(version MATCHES ${version_regex_2})
    set(count 2)
  elseif(version MATCHES ${version_regex_3})
    set(count 3)
  elseif(version MATCHES ${version_regex_4})
    set(count 4)
  endif()

  string(REGEX REPLACE "^([0-9]+)(\\.[0-9]+)?(\\.[0-9]+)?(\\.[0-9]+)?"
      "\\1" major "${version}")

  if(NOT count LESS 2)
    string(REGEX REPLACE "^[0-9]+\\.([0-9]+)(\\.[0-9]+)?(\\.[0-9]+)?"
        "\\1" minor "${version}")
  else()
    set(minor "0")
  endif()

  if(NOT count LESS 3)
    string(REGEX REPLACE "^[0-9]+\\.[0-9]+\\.([0-9]+)(\\.[0-9]+)?"
        "\\1" patch "${version}")
  else()
    set(patch "0")
  endif()

  if(NOT count LESS 4)
    string(REGEX REPLACE "^[0-9]+\\.[0-9]+\\.[0-9]+\\.([0-9]+)"
        "\\1" tweak "${version}")
  else()
    set(tweak "0")
  endif()
  
  set(${out_major} "${major}" PARENT_SCOPE)
  set(${out_minor} "${minor}" PARENT_SCOPE)
  set(${out_patch} "${patch}" PARENT_SCOPE)
  set(${out_tweak} "${tweak}" PARENT_SCOPE)
endfunction()
