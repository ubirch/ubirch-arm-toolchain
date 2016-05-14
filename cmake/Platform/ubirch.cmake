# Based on https://github.com/ARMmbed/target-mbed-gcc/blob/master/CMake/Platform/mbedOS.cmake
# Apache 2.0 licensed
# Copyright (C) 2014-2015 ARM Limited. All rights reserved.
# Copyright (C) 2016 ubirch GmbH
#
#include(Compiler/GNU)

set(CMAKE_EXECUTABLE_SUFFIX ".elf" CACHE STRING FORCE "")

set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS FALSE)

set(CMAKE_STATIC_LIBRARY_PREFIX "")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")
set(CMAKE_EXECUTABLE_SUFFIX ".elf")
set(CMAKE_C_OUTPUT_EXTENSION ".o")
set(CMAKE_ASM_OUTPUT_EXTENSION ".o")
set(CMAKE_CXX_OUTPUT_EXTENSION ".o")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# set default compilation flags
set(_C_FAMILY_FLAGS "${MCU_SPEC_C_FLAGS} -mthumb -MMD -MP -fno-common -fno-exceptions -fno-unwind-tables -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -mapcs-frame -Wall")

#set(CMAKE_MODULE_LINKER_FLAGS_INIT "${_C_FAMILY_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_C_FAMILY_FLAGS} ${MCU_SPEC_LINKER_FLAGS}")

# if GCC_PRINTF_FLOAT is set or not present, include float printing
if ((NOT DEFINED UBIRCH_CFG_GCC_PRINTF_FLOAT) OR (UBIRCH_CFG_GCC_PRINTF_FLOAT))
  set(CMAKE_EXE_LINKER_FLAGS_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT} -Wl,-u,_printf_float")
endif ()
