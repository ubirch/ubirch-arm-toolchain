# CMake toolchain for ubirch ARM platform

This is a cross compiler [CMake](https://cmake.org) toolchain for the
[ARM GCC compiler](https://launchpad.net/gcc-arm-embedded) for the [ubirch](https://ubirch.com/) hardware platform.
The toolchain is pretty generic and based on the [ARM mbed target](https://github.com/ARMmbed/target-mbed-gcc).

## Usage

1. Check out the toolchain: `git clone git@github.com:ubirch/ubirch-arm-toolchain.git`
2. To use the toolchain, create a build directory outside of your source tree. Then either run
   put the toolchain file into your main `CMakeLists.txt` (see [example](CMakeLists.txt)) or run `cmake`
   with a reference to the toolchain file:
  ```
  cd <build-dir>
  cmake <source-dir> -DCMAKE_TOOLCHAIN_FILE=<toolchain-dir>/cmake/ubirch-arm-gcc-toolchain.cmake
  ```
3. Finally, run `make` (or `make VERBOSE=1`) if you want to see everything).

## Contents

- `bin`
    - `blhost` - directory containing the blhost executable for flashing via USB (Linux, Mac, Windows)
- `cmake`
    - `ubirch-arm-gcc-toolchain.cmake` - __the toolchain file__
    - `Platform`
        * `ubirch.cmake` - general settings for [C](https://en.wikipedia.org/wiki/C_(programming_language))-class compilers, search paths and file suffixes
        * `ubirch-GNU-C.cmake` - [GNU-C](https://gcc.gnu.org/), and
          [ASM](https://en.wikipedia.org/wiki/Assembly_language#Assembler) compiler setting
        * `ubirch-GNU-CXX.cmake` - [GNU-CXX](https://gcc.gnu.org/) compiler settings
    - `Utils`
        * `require.cmake` - utility function to suport `provide()`/`require()` mechanics (part of toolchain)
        * `flashing.cmake` - utility macro `prepare_flash()` for simpler flashing (part of toolchain)
        * `flash.jlink.in` - template for flashing via [SEGGER JLink](https://www.segger.com/jlink-debug-probes.html)
        * `gdbinit` - init file for debugging with the [GDB](https://www.gnu.org/software/gdb/) debugger
        * `gdbinit_flash` - init file for flashing via [GDB](https://www.gnu.org/software/gdb/) debugger
- `CMakeLists.txt` - an example how to apply the toolchain file directly
- `example`
    * `CMakeLists.txt` - an example for a compiling a simple program
    * `main.c` - an example program (does nothing, not even `hello world`)
- `README.md` - this read me file
- `.gitignore` - tells git what to ignore (i.e. [C](https://en.wikipedia.org/wiki/C_(programming_language)),
   [C++](https://en.wikipedia.org/wiki/C%2B%2B), [CLion](https://www.jetbrains.com/clion/), and
   [CMake](https://cmake.org) intermediate files)
- `.editorconfig` - editor configuration (only [unix LF](https://en.wikipedia.org/wiki/Newline), 2 spaces indent)

## Extra

The toolchain provides two functions for providing and requiring exported packages. This is useful for cross-compiled
builds where we don't want to copy the libs into other projects, but rather require them. This is somewhat similar
to maven build tools.

However, the `provide` function exports directly from the build tree, which may break downstream builds if you make
changes. Should work well, in cases where support libraries are downloaded, built and simply used.

The `provide` function also exports a special config for the `CMAKE_BUILD_TYPE`, so downstream projects may request
a certain build type using `require`.

To support easier flashing, a macro `prepare_flash` is available which creates extra targets that
make flashing and debugging simpler.

### Examples

In a `kinetis-sdk.cmake` file we might export the KinetisSDK:
```
provide(PACKAGE KinetisSDK MCU MK82F25615 VERSION 2.0 TARGETS ksdk20 mmcau)
```

In a `my-project.cmake` file we can then (if we use this toolchain!), require KinetisSDK:
```
require(PACKAGE KinetisSDK MCU MK82F25615 VERSION 2.0)
```

## License

If not otherwise noted in the individual files, the code in this repository is

__Copyright &copy; 2016 [ubirch](http://ubirch.com) GmbH, Author: Matthias L. Jugel__

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
