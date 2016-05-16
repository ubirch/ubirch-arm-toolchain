# Based on https://github.com/ARMmbed/target-mbed-gcc/blob/master/CMake/toolchain.cmake
# Apache 2.0 licensed
# Copyright (C) 2014-2015 ARM Limited. All rights reserved.
# Copyright (C) 2016 ubirch GmbH

# Configurables:
#  UBIRCH_CFG_GCC_PRINTF_FLOAT - set to include float into printf lib
#
if (UBIRCH_GCC_TOOLCHAIN_INCLUDED)
  return()
endif ()
set(UBIRCH_GCC_TOOLCHAIN_INCLUDED 1)

# if there is not build type set, we default to MinSizeRel
set(CMAKE_BUILD_TYPE "MinSizeRel" CACHE STRING "build type")
message(STATUS "build type: ${CMAKE_BUILD_TYPE}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

set(CMAKE_SYSTEM_NAME ubirch)
set(CMAKE_SYSTEM_VERSION 1)
SET(CMAKE_SYSTEM_PROCESSOR arm)

find_program(ARM_NONE_EABI_GCC arm-none-eabi-gcc)
find_program(ARM_NONE_EABI_GPP arm-none-eabi-g++)
find_program(ARM_NONE_EABI_OBJCOPY arm-none-eabi-objcopy)
find_program(ARM_NONE_EABI_OBJDUMP arm-none-eabi-objdump)

# macro to print an info message in case we didn't find the compiler executables
macro(gcc_program_notfound progname)
  message("**************************************************************************\n")
  message(" ERROR: the arm gcc program ${progname} could not be found\n")
  if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" OR CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    message(" you can install the ARM GCC embedded compiler tools from:")
    message(" https://launchpad.net/gcc-arm-embedded/+download ")
  elseif (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    message(" it is included in the arm-none-eabi-gcc package that you can install")
    message(" with homebrew:\n")
    message("   brew tap ARMmbed/homebrew-formulae")
    message("   brew install arm-none-eabi-gcc")
  endif ()
  message("\n**************************************************************************")
  message(FATAL_ERROR "missing program prevents build")
  return()
endmacro(gcc_program_notfound)

if (NOT ARM_NONE_EABI_GCC)
  gcc_program_notfound("arm-none-eabi-gcc")
endif ()
if (NOT ARM_NONE_EABI_GPP)
  gcc_program_notfound("arm-none-eabi-g++")
endif ()
if (NOT ARM_NONE_EABI_OBJCOPY)
  gcc_program_notfound("arm-none-eabi-objcopy")
endif ()
if (NOT ARM_NONE_EABI_OBJDUMP)
  gcc_program_notfound("arm-none-eabi-objdump")
endif ()

# Set the compiler to ARM-GCC
if (CMAKE_VERSION VERSION_LESS "3.6.0")
  include(CMakeForceCompiler)
  cmake_force_c_compiler("${ARM_NONE_EABI_GCC}" GNU)
  cmake_force_cxx_compiler("${ARM_NONE_EABI_GPP}" GNU)
else ()
  # from 3.5 the force_compiler macro is deprecated: CMake can detect
  # arm-none-eabi-gcc as being a GNU compiler automatically
  set(CMAKE_C_COMPILER "${ARM_NONE_EABI_GCC}")
  set(CMAKE_CXX_COMPILER "${ARM_NONE_EABI_GPP}")
endif ()

set(CMAKE_INSTALL_PREFIX $ENV{HOME}/.cmake/repository/arm-none-eabi CACHE STRING "" FORCE)
message(STATUS "Installation prefix: ${CMAKE_INSTALL_PREFIX}")

include(CMakePackageConfigHelpers)

#!
# @brief provide this package in several configurations
# @param PACKAGE the package name
# @param VERSION the version to provide
# @param TARGETS all targets to be exported
#
macro(provide)
  cmake_parse_arguments(PROVIDE "" "PACKAGE;VERSION" "TARGETS" ${ARGN})

#  message(STATUS "PACKAGE: ${PROVIDE_PACKAGE}")
#  message(STATUS "VERSION: ${PROVIDE_VERSION}")
#  message(STATUS "TARGETS: ${PROVIDE_TARGETS}")
#  message(STATUS "${REQUIRE_UNPARSED_ARGUMENTS}")

  # for the MinSizeRel build type, also write a generic config file
  if (CMAKE_BUILD_TYPE MATCHES MinSizeRel)
    export(TARGETS ${PROVIDE_TARGETS} FILE ${PROVIDE_PACKAGE}Config.cmake)
    write_basic_package_version_file(
      "${CMAKE_CURRENT_BINARY_DIR}/${PROVIDE_PACKAGE}ConfigVersion.cmake"
      VERSION ${PROVIDE_VERSION}
      COMPATIBILITY AnyNewerVersion
    )
  endif ()

  export(TARGETS ${PROVIDE_TARGETS} FILE ${PROVIDE_PACKAGE}${CMAKE_BUILD_TYPE}Config.cmake)
  write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${PROVIDE_PACKAGE}${CMAKE_BUILD_TYPE}ConfigVersion.cmake"
    VERSION ${PROVIDE_VERSION}}
    COMPATIBILITY AnyNewerVersion
  )

  # register this target in the cmake registry
  export(PACKAGE ${PROVIDE_PACKAGE})
endmacro()

#!
# @brief Find a package with an optional build type.
# @param package the package name
# @param version the version required
# @param type the optional build type (default: MinSizeRel)
#
macro(require)
  cmake_parse_arguments(REQUIRE "OPTIONAL" "PACKAGE;VERSION;BUILD_TYPE" "" ${ARGN})

#  message(STATUS "PACKAGE: ${REQUIRE_PACKAGE}")
#  message(STATUS "VERSION: ${REQUIRE_VERSION}")
#  message(STATUS "BUILD_TYPE: ${REQUIRE_BUILD_TYPE}")
#  message(STATUS "OPTIONAL: ${REQUIRE_OPTIONAL}")
#  message(STATUS "${REQUIRE_UNPARSED_ARGUMENTS}")

  if (NOT REQUIRE_OPTIONAL)
    set(REQUIRED "REQUIRED")
  else ()
    set(REQUIRED "QUIET")
  endif ()

  if (NOT REQUIRE_BUILD_TYPE STREQUAL "")
    find_package("${REQUIRE_PACKAGE}" "${REQUIRE_VERSION}" ${REQUIRED} NAMES "${REQUIRE_PACKAGE}${REQUIRE_BUILD_TYPE}")
  endif ()

  if (NOT ${REQUIRE_PACKAGE}_DIR)
    if (NOT REQUIRE_OPTIONAL)
      message(STATUS "Can't find ${REQUIRE_PACKAGE} for build type ${REQUIRE_BUILD_TYPE}, trying default.")
    endif ()
    find_package("${REQUIRE_PACKAGE}" "${REQUIRE_VERSION}" ${REQUIRED})
  endif ()
  if (${REQUIRE_PACKAGE}_DIR)
    message(STATUS "${REQUIRE_PACKAGE} version: ${REQUIRE_VERSION}")
  endif ()
endmacro()
