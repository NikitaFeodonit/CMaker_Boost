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

# Copyright (c) 2013, Ruslan Baratov
# All rights reserved.

function(bcm_status_debug)
  if(bcm_STATUS_DEBUG)
    string(TIMESTAMP timestamp)
    if(bcm_CACHE_RUN)
      set(type "DEBUG (CACHE RUN)")
    else()
      set(type "DEBUG")
    endif()
    message(STATUS "[bcm *** ${type} *** ${timestamp}] ${ARGV}")
  endif()
endfunction()
