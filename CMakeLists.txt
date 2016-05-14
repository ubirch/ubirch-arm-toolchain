cmake_minimum_required(VERSION 3.0.2)

set(CMAKE_TOOLCHAIN_FILE cmake/ubirch-arm-gcc-toolchain.cmake)

project(ubirch-toolchain-example C CXX ASM)
add_subdirectory(example)
