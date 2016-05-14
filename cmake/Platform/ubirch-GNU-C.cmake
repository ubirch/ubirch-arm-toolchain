# Based on https://github.com/ARMmbed/target-mbed-gcc/blob/master/CMake/Platform/mbedOS-GNU-C.cmake
# Apache 2.0 licensed
# Copyright (C) 2014-2015 ARM Limited. All rights reserved.
# Copyright (C) 2016 ubirch GmbH

set(EXPLICIT_INCLUDES "")
if((CMAKE_VERSION VERSION_GREATER "3.4.0") OR (CMAKE_VERSION VERSION_EQUAL "3.4.0"))
  # from CMake 3.4 <INCLUDES> are separate to <FLAGS> in the
  # CMAKE_<LANG>_COMPILE_OBJECT, CMAKE_<LANG>_CREATE_ASSEMBLY_SOURCE, and
  # CMAKE_<LANG>_CREATE_PREPROCESSED_SOURCE commands
  set(EXPLICIT_INCLUDES "<INCLUDES> ")
endif()

# Override the link rules:
set(CMAKE_C_CREATE_SHARED_LIBRARY "echo 'shared libraries not supported' && 1")
set(CMAKE_C_CREATE_SHARED_MODULE  "echo 'shared modules not supported' && 1")
set(CMAKE_C_CREATE_STATIC_LIBRARY "<CMAKE_AR> -cr <LINK_FLAGS> <TARGET> <OBJECTS>")
set(CMAKE_C_COMPILE_OBJECT        "<CMAKE_C_COMPILER> <DEFINES> ${EXPLICIT_INCLUDES}<FLAGS> -o <OBJECT> -c <SOURCE>")
# <LINK_LIBRARIES> is grouped with system libraries so that system library
# functions (e.g. malloc) can be overridden by symbols in <LINK_LIBRARIES>
set(CMAKE_C_LINK_EXECUTABLE       "<CMAKE_C_COMPILER> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> -Wl,-Map,<TARGET>.map")
set(CMAKE_C_LINK_EXECUTABLE       "${CMAKE_C_LINK_EXECUTABLE} -Wl,--start-group <OBJECTS> <LINK_LIBRARIES>")
set(CMAKE_C_LINK_EXECUTABLE       "${CMAKE_C_LINK_EXECUTABLE} ${GLOBALLY_LINKED_TARGET_LIBS}")
set(CMAKE_C_LINK_EXECUTABLE       "${CMAKE_C_LINK_EXECUTABLE} -lm -lc -lgcc -lm -lc -lgcc -lnosys -Wl,--end-group -o <TARGET>")

set(CMAKE_C_FLAGS_DEBUG_INIT          "-g -std=c99 ${_C_FAMILY_FLAGS}")
set(CMAKE_C_FLAGS_MINSIZEREL_INIT     "-Os -DNDEBUG -std=c99 ${_C_FAMILY_FLAGS}")
set(CMAKE_C_FLAGS_RELEASE_INIT        "-Os -DNDEBUG -std=c99 ${_C_FAMILY_FLAGS}")
set(CMAKE_C_FLAGS_RELWITHDEBINFO_INIT "-Os -g -DNDEBUG -std=c99 ${_C_FAMILY_FLAGS}")
set(CMAKE_INCLUDE_SYSTEM_FLAG_C       "-isystem ")

# somehow the flags for ASM get clobbered ...
set(CMAKE_ASM_FLAGS_DEBUG             "-g ${_C_FAMILY_FLAGS}" CACHE STRING "")
set(CMAKE_ASM_FLAGS_MINSIZEREL        "-Os -DNDEBUG ${_C_FAMILY_FLAGS}" CACHE STRING "")
set(CMAKE_ASM_FLAGS_RELEASE           "-Os -DNDEBUG ${_C_FAMILY_FLAGS}" CACHE STRING "")
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO    "-Os -g -DNDEBUG -DFOO ${_C_FAMILY_FLAGS}" CACHE STRING "")
set(CMAKE_INCLUDE_SYSTEM_FLAG_ASM     "-isystem ")

if(UBIRCH_CFG_DEBUG_OPTIONS_COVERAGE)
  set(CMAKE_C_LINK_EXECUTABLE         "${CMAKE_C_LINK_EXECUTABLE} -fprofile-arcs -lgcov")
endif()
