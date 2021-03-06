# Based on https://github.com/ARMmbed/target-mbed-gcc/blob/master/CMake/Platform/mbedOS-GNU-CXX.cmake
# Apache 2.0 licensed
# Copyright (C) 2014-2015 ARM Limited. All rights reserved.
# Copyright (C) 2016 ubirch GmbH
# can't test the compiler because it cross-compiles
set(CMAKE_CXX_COMPILER_WORKS TRUE)

execute_process(
  COMMAND "${CMAKE_CXX_COMPILER}" "--version"
  OUTPUT_VARIABLE _ARM_GNU_GCC_VERSION_OUTPUT
)
string(REGEX REPLACE ".* ([0-9]+[.][0-9]+[.][0-9]+) .*" "\\1" _ARM_GNU_GCC_VERSION "${_ARM_GNU_GCC_VERSION_OUTPUT}")
message(STATUS "GCC version: ${_ARM_GNU_GCC_VERSION}")

set(EXPLICIT_INCLUDES "")
if((CMAKE_VERSION VERSION_GREATER "3.4.0") OR (CMAKE_VERSION VERSION_EQUAL "3.4.0"))
  # from CMake 3.4 <INCLUDES> are separate to <FLAGS> in the
  # CMAKE_<LANG>_COMPILE_OBJECT, CMAKE_<LANG>_CREATE_ASSEMBLY_SOURCE, and
  # CMAKE_<LANG>_CREATE_PREPROCESSED_SOURCE commands
  set(EXPLICIT_INCLUDES "<INCLUDES> ")
endif()

set(CMAKE_CXX_CREATE_SHARED_LIBRARY "echo 'shared libraries not supported' && 1")
set(CMAKE_CXX_CREATE_SHARED_MODULE  "echo 'shared modules not supported' && 1")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> -cr <LINK_FLAGS> <TARGET> <OBJECTS>")
set(CMAKE_CXX_COMPILE_OBJECT        "<CMAKE_CXX_COMPILER> <DEFINES> ${EXPLICIT_INCLUDES}<FLAGS> -o <OBJECT> -c <SOURCE>")
# <LINK_LIBRARIES> is grouped with system libraries so that system library
# functions (e.g. malloc) can be overridden by symbols in <LINK_LIBRARIES>
set(CMAKE_CXX_LINK_EXECUTABLE       "<CMAKE_CXX_COMPILER> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> -Wl,-Map,<TARGET>.map")
set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} -Wl,--start-group <OBJECTS> <LINK_LIBRARIES>")
set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} ${GLOBALLY_LINKED_TARGET_LIBS} -lstdc++ -lsupc++")
set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} -lm -lc -lgcc -lstdc++ -lsupc++ -lm -lc -lgcc")
set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} -Wl,--end-group  --specs=nano.specs -o <TARGET>")

set(CMAKE_CXX_FLAGS_DEBUG_INIT          "-g ${_C_FAMILY_FLAGS} ${_C_DEBUG_FLAGS}")
set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT     "-Os -DNDEBUG ${_C_FAMILY_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE_INIT        "-Os -DNDEBUG ${_C_FAMILY_FLAGS}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "-Os -g -DNDEBUG ${_C_FAMILY_FLAGS} ${_C_DEBUG_FLAGS}")
set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX       "-isystem ")

if(UBIRCH_CFG_DEBUG_OPTIONS_COVERAGE)
  set(CMAKE_CXX_LINK_EXECUTABLE       "${CMAKE_CXX_LINK_EXECUTABLE} -fprofile-arcs -lgcov")
endif()
