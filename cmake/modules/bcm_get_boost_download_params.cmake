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

include(bcm_get_version_parts)
include(bcm_fatal_error)

function(bcm_get_boost_download_params
    version
    out_url out_sha1 out_src_dir_name out_tar_file_name)

  bcm_get_version_parts(${version} major minor patch tweak)

  set(boost_base_url "https://downloads.sourceforge.net/project/boost/boost")
  
  # TODO: get url and sha1 for all boost version
  if(version VERSION_EQUAL "1.64.0")
    set(boost_sha1 "51421ef259a4530edea0fbfc448460fcc5c64edb")
  endif()
  if(version VERSION_EQUAL "1.63.0")
    set(boost_sha1 "9f1dd4fa364a3e3156a77dc17aa562ef06404ff6")
  endif()

  if(NOT DEFINED boost_sha1)
    bcm_fatal_error("Boost version ${version} is not supported.")
  endif()

  set(version_underscore "${major}_${minor}_${patch}")
  set(boost_src_name "boost_${version_underscore}")
  set(boost_tar_file_name "${boost_src_name}.tar.bz2")
  set(boost_url "${boost_base_url}/${version}/${boost_tar_file_name}")

  set(${out_url} "${boost_url}" PARENT_SCOPE)
  set(${out_sha1} "${boost_sha1}" PARENT_SCOPE)
  set(${out_src_dir_name} "${boost_src_name}" PARENT_SCOPE)
  set(${out_tar_file_name} "${boost_tar_file_name}" PARENT_SCOPE)
endfunction()
