find_program(JLINK JLinkExe)
if (JLINK-NOTFOUND)
  message(STATUS "For direct flashing, install SEGGER JLink...")
else ()
  message(STATUS "JLink: ${JLINK} found.")
endif ()
find_file(JLINK_IN flash.jlink.in HINTS ${CMAKE_CURRENT_LIST_DIR})

# add the gdb for the macro below
find_program(CMAKE_GDB arm-none-eabi-gdb)
find_program(CGDB cgdb)
if (CGDB-NOTFOUND)
  message(STATUS "For debugging, install cgdb...")
else ()
  message(STATUS "debugger: ${CGDB} found.")
endif ()

# we need this gdbinit file for flashing directly
# needs "JLinkGDBServer  -if SWD -device MK82FN256xxx15" to be running
set(GDBINIT ${CMAKE_CURRENT_SOURCE_DIR}/.gdbinit)
message(STATUS "gdbinit: ${GDBINIT}")

# create special target that directly flashes
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  set(MBED_FLASH_DIR /Volumes/MBED)
else ()
  if (NOT MBED_FLASH_DIR)
    message(STATUS "!! Please set MBED_FLASH_DIR to the directory where MBED mounts!")
  endif ()
endif ()
message(STATUS "MBED flash directory: ${MBED_FLASH_DIR}")

macro(prepare_flash)
  cmake_parse_arguments(FLASH "JLINK" "TARGET;DIR;DEVICE;SPEED;START_ADDRESS" "" ${ARGN})

  if (NOT FLASH_TARGET)
    message(FATAL_ERROR "prepare_flash() needs at least a TARGET to flash!")
  endif ()
  if (NOT FLASH_DIR)
    set(FLASH_DIR ${MBED_FLASH_DIR})
  endif ()

  if (ARM_NONE_EABI_SIZE)
    add_custom_command(
      TARGET ${FLASH_TARGET} POST_BUILD
      COMMAND ${ARM_NONE_EABI_SIZE} $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.elf
    )
  endif ()

  add_custom_command(
    TARGET ${FLASH_TARGET} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${FLASH_TARGET}> $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.bin
  )

  if (BOARD MATCHES "ubirch.*" OR FLASH_JLINK)
    if (JLINK)
      if (NOT FLASH_INTERFACE)
        set(FLASH_INTERFACE SWD)
      endif ()
      if (NOT FLASH_DEVICE)
        set(FLASH_DEVICE MK82FN256XXX15)
      endif ()
      if (NOT FLASH_SPEED)
        set(FLASH_SPEED 4000)
      endif ()
      if (NOT FLASH_START_ADDRESS)
        set(FLASH_START_ADDRESS 0x0)
      endif ()

      set(FLASH_TARGET_FILE ${CMAKE_CURRENT_BINARY_DIR}/${FLASH_TARGET}.bin)
      configure_file(${JLINK_IN} ${CMAKE_CURRENT_BINARY_DIR}/flash.jlink @ONLY)

      # flash directly calling JLinkExe with a script
      add_custom_target(${FLASH_TARGET}-flash
        DEPENDS ${FLASH_TARGET}
        COMMAND ${JLINK} -if ${FLASH_INTERFACE} -device ${FLASH_DEVICE} -speed ${FLASH_SPEED} ${CMAKE_CURRENT_BINARY_DIR}/flash.jlink
        )
    else ()
      # create special target that directly flashes
      add_custom_target(${FLASH_TARGET}-flash
        DEPENDS ${FLASH_TARGET}
        COMMAND ${CMAKE_GDB} -x ${GDBINIT}_flash --batch $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.elf
        )
    endif ()
  else ()
    add_custom_target(${FLASH_TARGET}-flash
      DEPENDS ${FLASH_TARGET}
      COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.bin ${FLASH_DIR}
      )
  endif ()

  # print out some helpful hints to debug
  add_custom_target(${FLASH_TARGET}-gdb
    DEPENDS ${FLASH_TARGET}
    COMMAND echo "==== DEBUG COMMAND ====="
    COMMAND echo cgdb -d ${CMAKE_GDB} -x ${GDBINIT} $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.elf
    COMMAND echo "========================")
endmacro()
