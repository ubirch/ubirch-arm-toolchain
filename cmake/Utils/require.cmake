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
  cmake_parse_arguments(PROVIDE "" "PACKAGE;MCU;BOARD;VERSION" "TARGETS" ${ARGN})
  if (PROVIDE_MCU AND PROVIDE_BOARD)
    message(FATAL_ERROR "MCU and BOARD set, set only one of both!")
  endif ()

  # set the spec for this package (defines part of the namespace for targets)
  if (PROVIDE_BOARD)
    set(PROVIDE_SPEC ${PROVIDE_BOARD})
  elseif (PROVIDE_MCU)
    set(PROVIDE_SPEC ${PROVIDE_MCU})
  else ()
    status(FATAL_ERROR "Please provide with either MCU or BOARD setting.")
  endif ()

  message(STATUS "PROVIDE: ${PROVIDE_PACKAGE}::${PROVIDE_SPEC}:: ${PROVIDE_VERSION}, ${CMAKE_BUILD_TYPE}")

  set(PACKAGE_NAME ${PROVIDE_PACKAGE}-${PROVIDE_SPEC})
  export(
    TARGETS ${PROVIDE_TARGETS}
    NAMESPACE ${PROVIDE_PACKAGE}::${PROVIDE_SPEC}::
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
  cmake_parse_arguments(REQUIRE "OPTIONAL" "PACKAGE;MCU;BOARD;VERSION;BUILD_TYPE" "" ${ARGN})
  if (REQUIRE_MCU AND REQUIRE_BOARD)
    message(FATAL_ERROR "MCU and BOARD set, set only one of both!")
  endif ()

  # set the spec for this package (defines part of the namespace for targets)
  if (REQUIRE_BOARD)
    set(REQUIRE_SPEC ${REQUIRE_BOARD})
  elseif (REQUIRE_MCU)
    set(REQUIRE_SPEC ${REQUIRE_MCU})
  else ()
    message(FATAL_ERROR "Please require with either MCU or BOARD setting.")
  endif ()

  # if there is no build type set, set it to the current build type
  if (NOT REQUIRE_BUILD_TYPE OR "${REQUIRE_BUILD_TYPE}" STREQUAL "")
    set(REQUIRE_BUILD_TYPE "${CMAKE_BUILD_TYPE}")
  endif ()

  message(STATUS "REQUIRE: ${REQUIRE_PACKAGE}::${REQUIRE_SPEC} (${REQUIRE_VERSION}, ${REQUIRE_BUILD_TYPE})")

  if (NOT REQUIRE_OPTIONAL)
    set(REQUIRED "REQUIRED")
  else ()
    set(REQUIRED "QUIET")
  endif ()

  set(PACKAGE_NAME ${REQUIRE_PACKAGE}-${REQUIRE_SPEC})

  # try to find the package using the required MCU and BUILD_TYPE
  find_package(
    ${REQUIRE_PACKAGE} ${REQUIRE_VERSION} QUIET
    NAMES ${PACKAGE_NAME}-${REQUIRE_BUILD_TYPE}
  )

  # if no specific build config has been found, try default (any)
  if (NOT ${REQUIRE_PACKAGE}_DIR)
    if (NOT REQUIRE_OPTIONAL)
      message(STATUS "${REQUIRE_PACKAGE}::${REQUIRE_SPEC}:: (${REQUIRE_BUILD_TYPE}) not found, trying default.")
    endif ()
    find_package(
      ${REQUIRE_PACKAGE} ${REQUIRE_VERSION}
      NAMES ${PACKAGE_NAME}
    )
  endif ()

  if (${REQUIRE_PACKAGE}_DIR)
    set(${REQUIRE_PACKAGE}_VERSION ${${REQUIRE_PACKAGE}_VERSION} CACHE STRING "" FORCE)
    set(${REQUIRE_PACKAGE}_VERSION_MAJOR ${${REQUIRE_PACKAGE}_VERSION_MAJOR} CACHE STRING "" FORCE)
    set(${REQUIRE_PACKAGE}_VERSION_MINOR ${${REQUIRE_PACKAGE}_VERSION_MINOR} CACHE STRING "" FORCE)
    set(${REQUIRE_PACKAGE}_VERSION_PATCH ${${REQUIRE_PACKAGE}_VERSION_PATCH} CACHE STRING "" FORCE)

    message(STATUS "${REQUIRE_PACKAGE} version: ${${REQUIRE_PACKAGE}_VERSION}, ${${REQUIRE_PACKAGE}_DIR}")
#    message(STATUS "${${REQUIRE_PACKAGE}_DIR}")
  endif ()
endfunction()
