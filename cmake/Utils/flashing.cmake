# @file

# find some of the support files which should be in this directory
find_file(JLINK_IN flash.jlink.in HINTS ${CMAKE_CURRENT_LIST_DIR})
find_file(GDBINIT_FILE gdbinit HINTS ${CMAKE_CURRENT_LIST_DIR})
find_file(GDBINIT_FLASH_FILE gdbinit_flash HINTS ${CMAKE_CURRENT_LIST_DIR})

# try to find jlink and blhost (for all host system types)
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
  file(GLOB JLINK_PATH "C:/Program Files*/SEGGER/Jlink*")
  find_program(JLINK JLink.exe PATHS ${JLINK_PATH})
  find_program(BLHOST blhost.exe PATHS ${CMAKE_CURRENT_LIST_DIR}/../../bin/blhost/win)
elseif (CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  set(PROCESSOR ${CMAKE_HOST_SYSTEM_PROCESSOR})
  if (PROCESSOR MATCHES "x86_64")
    set(PROCESSOR "amd64")
  endif ()
  find_program(JLINK JLinkExe)
  find_program(BLHOST blhost PATHS ${CMAKE_CURRENT_LIST_DIR}/../../bin/blhost/linux/${PROCESSOR})
elseif (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  find_program(JLINK JLinkExe)
  find_program(BLHOST blhost PATHS ${CMAKE_CURRENT_LIST_DIR}/../../bin/blhost/mac)
  set(MBED_FLASH_DIR /Volumes/MBED CACHE STRING "MBED flash directory")
else ()
  message(WARNING "Can't identify host system: ${CMAKE_HOST_SYSTEM}")
endif ()

find_program(GDB arm-none-eabi-gdb)
find_program(CGDB cgdb)

if (NOT BLHOST)
  message(STATUS "Missing blhost for your system, can't flash ubirch board via USB.")
else ()
  message(STATUS "blhost: ${BLHOST} found.")
endif ()
if (NOT JLINK)
  message(STATUS "For direct flashing, install SEGGER JLink...")
else ()
  message(STATUS "JLink: ${JLINK} found.")
endif ()

# add the gdb for the macro below
if (NOT CGDB)
  message(STATUS "For debugging, install cgdb...")
else ()
  message(STATUS "Debugger: ${CGDB} found.")
endif ()

# create special target that directly flashes
if (NOT MBED_FLASH_DIR)
  message(STATUS "!! Please set MBED_FLASH_DIR to the directory where MBED mounts!")
else ()
  message(STATUS "MBED flash directory: ${MBED_FLASH_DIR}")
endif ()

#!
# @brief prepare target for flashing directly, via USB, MBED mounted dir, or GDB
#
# This macro makes flashing simpler, by selecting a number of options to directly flash
# via the JLink Debugger or just copying the target binary to the MBED mounted directory
# or via a load command to a GDB server.
#
# ubirch boards also have the ability to directly flash using blhost and USB. Initially
# this requires disconnecting, pressing the button and connecting, then flashing.
# Using the ubirch board firmware, pressing the button will enter the bootloader.
#
# It creates two extra targets: <NAME>-flash for flashing and <NAME>-gdb for showing a gdb
# command line to start debugging.
#
# Examples:
# - prepare_flash(TARGET example DIR /Volumes/MBED)
# - prepare_flash(TARGET example JLINK DEVICE MK82FN256xxx15 SPEED 1000 START_ADDRESS 0x0)
#
# @param TARGET the target to flash
# @param JLINK (optional) if your board is not automatically selecting JLINK, you can for it to use JLINK
# @param GDB (optional) force select gdb flashing, requires a gdb server running
# @param DIR (optional) the directory where to copy the binary for flashing (MBED method)
# @param DEVICE (optional) the jlink device id to select
# @param SPEED the jlink speed in kHz (default is 4000)
# @param START_ADDRESS the flash start address (default is 0x0)
#
macro(prepare_flash)
  cmake_parse_arguments(FLASH "JLINK;GDB" "TARGET;DIR;DEVICE;SPEED;START_ADDRESS" "" ${ARGN})

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

  # Flashing the ubirch board works by invoking the ROM bootloader mode of the Kinetis device
  if (BOARD MATCHES "ubirch" AND NOT (FLASH_JLINK OR FLASH_GDB))
    if (NOT BLHOST)
      message(FATAL_ERROR "can't flash using USB, the required blhost executable was not found!")
    endif ()
    if (NOT FLASH_START_ADDRESS)
      set(FLASH_START_ADDRESS 0)
    endif ()
    message(STATUS "Flashing '${FLASH_TARGET}' to ubirch board directly via USB.")
    add_custom_target(${FLASH_TARGET}-flash
      DEPENDS ${FLASH_TARGET}
      COMMAND ${BLHOST} -u -- flash-erase-all
      COMMAND ${BLHOST} -u -- write-memory ${FLASH_START_ADDRESS} $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.bin
      COMMAND ${BLHOST} -u -- reset
      )
  elseif (FLASH_JLINK)
    # flash using JLink (either directly or via GDB)
    if (NOT FLASH_GDB AND JLINK)
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

      message(STATUS "Flashing '${FLASH_TARGET}' directly via JLink executable.")
      set(FLASH_TARGET_FILE ${CMAKE_CURRENT_BINARY_DIR}/${FLASH_TARGET}.bin)
      configure_file(${JLINK_IN} ${CMAKE_CURRENT_BINARY_DIR}/${FLASH_TARGET}-flash.jlink @ONLY)

      # flash directly calling JLinkExe with a script
      add_custom_target(${FLASH_TARGET}-flash
        DEPENDS ${FLASH_TARGET}
        COMMAND ${JLINK} -if ${FLASH_INTERFACE} -device ${FLASH_DEVICE} -speed ${FLASH_SPEED} ${CMAKE_CURRENT_BINARY_DIR}/${FLASH_TARGET}-flash.jlink
        )
    else ()
      message(STATUS "Flashing '${FLASH_TARGET}' indirectly via GDB server.")

      # create special target that directly flashes using the gdb server as an intermediate
      add_custom_target(${FLASH_TARGET}-flash
        DEPENDS ${FLASH_TARGET}
        COMMAND ${GDB} -x ${GDBINIT_FLASH_FILE} --batch $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.elf
        )
    endif ()
  else ()
    message(STATUS "Flashing '${FLASH_TARGET}' via MBED mounted directory.")
    # the FRDM boards support the MBED mounted disk flashing
    add_custom_target(${FLASH_TARGET}-flash
      DEPENDS ${FLASH_TARGET}
      COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.bin ${FLASH_DIR}
      )
  endif ()

  # print out some helpful hints to debug
  add_custom_target(${FLASH_TARGET}-gdb
    DEPENDS ${FLASH_TARGET}
    COMMAND echo "==== DEBUG COMMAND ====="
    COMMAND echo cgdb -d ${GDB} -x ${GDBINIT_FILE} $<TARGET_FILE_DIR:${FLASH_TARGET}>/${FLASH_TARGET}.elf
    COMMAND echo "========================")
endmacro()
