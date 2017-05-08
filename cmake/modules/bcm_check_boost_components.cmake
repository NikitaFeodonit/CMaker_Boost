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

# Based on the build-boost.sh from CrystaX NDK, https://www.crystax.net/,
# https://github.com/crystax/android-platform-ndk/blob/master/build/tools/build-boost.sh
# Based on the hunter,
# https://github.com/ruslo/hunter

include(bcm_fatal_error)

function(bcm_check_boost_components boost_version boost_components)
  macro(boost_component_list name version)
    list(APPEND BOOST_COMPONENT_NAMES ${name})
    set(BOOST_COMPONENT_${name}_VERSION ${version})
  endmacro()
  
  boost_component_list(atomic 1.53.0)
  boost_component_list(chrono 1.47.0)
  boost_component_list(container 1.48.0)
  boost_component_list(context 1.51.0)
  boost_component_list(coroutine 1.53.0)
  boost_component_list(coroutine2 1.59.0)
  boost_component_list(date_time 1.29.0)
  boost_component_list(exception 1.36.0)
  boost_component_list(fiber 1.62.0)
  boost_component_list(filesystem 1.30.0)
  boost_component_list(graph 1.18.0)
  boost_component_list(graph_parallel 1.40.0)
  boost_component_list(iostreams 1.33.0)
  boost_component_list(locale 1.48.0)
  boost_component_list(log 1.54.0)
  boost_component_list(math 1.23.0)
  boost_component_list(metaparse 1.61.0)
  boost_component_list(mpi 1.35.0)
  boost_component_list(program_options 1.32.0)
  boost_component_list(python 1.19.0)
  boost_component_list(random 1.15.0)
  boost_component_list(regex 1.18.0)
  boost_component_list(serialization 1.32.0)
  boost_component_list(signals 1.29.0)
  boost_component_list(system 1.35.0)
  boost_component_list(test 1.21.0)
  boost_component_list(thread 1.25.0)
  boost_component_list(timer 1.9.0)
  boost_component_list(type_erasure 1.54.0)
  boost_component_list(wave 1.33.0)

  bcm_print_var_value(boost_components)

  string(COMPARE EQUAL "${boost_components}" "only_headers" only_headers)
  if(only_headers)
    foreach(name IN LISTS BOOST_COMPONENT_NAMES)
      if(NOT ${boost_version} VERSION_LESS BOOST_COMPONENT_${name}_VERSION)
        list(APPEND boost_libs ${name})
      endif()
    endforeach()

    set(bcm_NOT_BUILD_LIBRARIES ${boost_libs} PARENT_SCOPE)
    return()
  endif()

  foreach(name IN LISTS boost_components)
    string(COMPARE EQUAL "${name}" "all" build_all_libs)
    if(build_all_libs)
      return()
    endif()
  
    if(${boost_version} VERSION_LESS BOOST_COMPONENT_${name}_VERSION)
      bcm_fatal_error("Boost of version ${boost_version} don't have the component ${name}.")
    endif()

    if(ANDROID)
      string(COMPARE EQUAL "${name}" "python" bad_component)
      if(bad_component)
        # TODO: CrystaX NDK has python
        bcm_fatal_error("Android NDK don't have python for Boost.Python.")
      endif()
      
      # Boost.Context in 1.57.0 and earlier don't support arm64.
      # Boost.Context in 1.61.0 and earlier don't support mips64.
      # Boost.Coroutine depends on Boost.Context.
      if((ANDROID_SYSROOT_ABI STREQUAL arm64
              AND NOT bcm_Boost_VERSION VERSION_GREATER "1.57.0")
          OR (ANDROID_SYSROOT_ABI STREQUAL mips64
              AND NOT bcm_Boost_VERSION VERSION_GREATER "1.61.0"))
        string(COMPARE EQUAL "${name}" "context" bad_component)
        if(bad_component)
          bcm_fatal_error("Boost.Context in boost of version ${bcm_Boost_VERSION} don't support ${ANDROID_SYSROOT_ABI}.")
        endif()

        string(COMPARE EQUAL "${name}" "coroutine" bad_component)
        if(bad_component)
          bcm_fatal_error("Boost.Coroutine in boost of version ${bcm_Boost_VERSION} don't support ${ANDROID_SYSROOT_ABI}.")
        endif()
      endif()
      
      # Starting from 1.59.0, there is Boost.Coroutine2 library,
      # which depends on Boost.Context too.
      if(ANDROID_SYSROOT_ABI STREQUAL mips64
              AND NOT bcm_Boost_VERSION VERSION_GREATER "1.61.0")
        string(COMPARE EQUAL "${name}" "coroutine2" bad_component)
        if(bad_component)
          bcm_fatal_error("Boost.Coroutine2 in boost of version ${bcm_Boost_VERSION} don't support ${ANDROID_SYSROOT_ABI}.")
        endif()
      endif()

    endif()
  endforeach()
endfunction()
