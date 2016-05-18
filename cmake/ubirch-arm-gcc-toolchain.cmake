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
# @brief provide this package in several configurations (adds namespace NAME::MCU::)
# @param PACKAGE the package name
# @param VERSION the version to provide
# @param TARGETS all targets to be exported
#
function(provide)
  cmake_parse_arguments(PROVIDE "" "PACKAGE;MCU;VERSION" "TARGETS" ${ARGN})

  message(STATUS "PROVIDE PACKAGE   : ${PROVIDE_PACKAGE}")
  message(STATUS "PROVIDE VERSION   : ${PROVIDE_VERSION}")
  message(STATUS "PROVIDE MCU       : ${PROVIDE_MCU}")
  message(STATUS "PROVIDE BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
  message(STATUS "PROVIDE TARGETS   : ${PROVIDE_TARGETS}")
  #  message(STATUS "${REQUIRE_UNPARSED_ARGUMENTS}")

  set(PACKAGE_NAME ${PROVIDE_PACKAGE}-${PROVIDE_MCU})
  export(
    TARGETS ${PROVIDE_TARGETS}
    NAMESPACE ${PROVIDE_PACKAGE}::${PROVIDE_MCU}::
    FILE ${PACKAGE_NAME}Targets.cmake
  )

  # write configuration for the package + build type
  write_basic_package_version_file(
    ${PACKAGE_NAME}-${CMAKE_BUILD_TYPE}ConfigVersion.cmake
    VERSION ${PROVIDE_VERSION}
    COMPATIBILITY SameMajorVersion
  )
  if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/package-config.cmake.in)
    configure_file(
      package-config.cmake.in
      ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}-${CMAKE_BUILD_TYPE}Config.cmake
      @ONLY
    )
  else ()
    file(
      WRITE
      ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}-${CMAKE_BUILD_TYPE}Config.cmake
      "include(\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}Targets.cmake)"
    )
  endif ()

  # for MinSizeRel also write a default config with no build type added
  if (CMAKE_BUILD_TYPE MATCHES "MinSizeRel|None" OR CMAKE_BUILD_TYPE STREQUAL "")
    write_basic_package_version_file(
      ${PACKAGE_NAME}ConfigVersion.cmake
      VERSION ${PROVIDE_VERSION}
      COMPATIBILITY AnyNewerVersion
    )
    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/package-config.cmake.in)
      configure_file(
        package-config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake
        @ONLY
      )
    else ()
      file(
        WRITE
        ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake
        "include(\${CMAKE_CURRENT_LIST_DIR}/${PACKAGE_NAME}Targets.cmake)"
      )
    endif ()
  endif ()

  # register this target in the cmake registry
  export(PACKAGE ${PROVIDE_PACKAGE})
endfunction()

#!
# @brief Find a package with an optional build type.
# @param package the package name
# @param version the version required
# @param type the optional build type (default: MinSizeRel)
#
function(require)
  cmake_parse_arguments(REQUIRE "OPTIONAL" "PACKAGE;MCU;VERSION;BUILD_TYPE" "" ${ARGN})
#  if (${REQUIRE_PACKAGE}_DIR)
#    message(STATUS "${REQUIRE_PACKAGE} already required.")
#    return()
#  endif ()

  # if there is no build type set, set it to the current build type
  if ("${REQUIRE_BUILD_TYPE}" STREQUAL "")
    set(REQUIRE_BUILD_TYPE "${CMAKE_BUILD_TYPE}")
  endif ()

  message(STATUS "REQUIRE: ${REQUIRE_PACKAGE} (${REQUIRE_VERSION}, MCU=${REQUIRE_MCU}, ${REQUIRE_BUILD_TYPE})")
  #  message(STATUS "${REQUIRE_UNPARSED_ARGUMENTS}")

  if (NOT REQUIRE_OPTIONAL)
    set(REQUIRED "REQUIRED")
  else ()
    set(REQUIRED "QUIET")
  endif ()

  set(PACKAGE_NAME ${REQUIRE_PACKAGE}-${REQUIRE_MCU})

  # try to find the package using the required MCU and BUILD_TYPE
  find_package(
    ${REQUIRE_PACKAGE} ${REQUIRE_VERSION} QUIET
    NAMES ${PACKAGE_NAME}-${REQUIRE_BUILD_TYPE}
  )

  # if no specific build config has been found, try default (any)
  if (NOT ${REQUIRE_PACKAGE}_DIR)
    if (NOT REQUIRE_OPTIONAL)
      message(STATUS "${REQUIRE_PACKAGE} (MCU=${REQUIRE_MCU}, ${REQUIRE_BUILD_TYPE}) not found, trying default.")
    endif ()
    find_package(
      ${REQUIRE_PACKAGE} ${REQUIRE_VERSION}
      NAMES ${PACKAGE_NAME}
    )
  endif ()

  if (${REQUIRE_PACKAGE}_DIR)
    message(STATUS "${REQUIRE_PACKAGE} version: ${REQUIRE_VERSION}, ${${REQUIRE_PACKAGE}_DIR}")
    message(STATUS "${${REQUIRE_PACKAGE}_DIR}")
  endif ()
endfunction()
