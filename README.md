# CMake toolchain for ubirch ARM

This is a cross compiler toolchain for the ARM GCC compiler for the [ubirch](https://ubirch.com/) hardware platform.
The toolchain is pretty generic and based on the [ARM mbed target](https://github.com/ARMmbed/target-mbed-gcc).

## Usage

1. Check out the toolchain: `git clone https://gitlab.com/ubirch/ubirch-arm-toolchain.git`
2. Either run cmake with a reference to the toolchain file (replace `<project>` and `<toolchain>` with
   your source directory and this toolchain directory):
    ```cmake <project> -DCMAKE_TOOLCHAIN_FILE=<toolchain>/cmake/ubirch-arm-gcc-toolchain.cmake```
3. Finally, run `make` (or `make VERBOSE=1` if you want to see everything).

## Contents

- `cmake`
    - __`ubirch-arm-gcc-toolchain.cmake`__ - __the toolchain file__
    - `Platform`
        * `ubirch.cmake` - general settings for C-class compilers, search paths and file suffixes
        * `ubirch-GNU-C.cmake` - GNU-C and ASM compiler setting
        * `ubirch-GNU-CXX.cmake` - GNU-CXX compiler settings
- `CMakeLists.txt` - an example how to apply the toolchain file directly
- `example`
    * `CMakeLists.txt` - an example for a compiling a simple program
    * `main.c` - an example program (does nothing, not even `hello world`)
- `README.md` - this read me file
- `.gitignore` - tells git what to ignore (i.e. C, C++, CLion, and CMake intermediate files)
- `.editorconfig` - editor configuration (only unix LF, 2 spaces indent)

## License

If not otherwise noted in the individual files, the code in this repository is

 __Copyright &copy; 2016 ubirch GmbH, Author: Matthias L. Jugel__

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
