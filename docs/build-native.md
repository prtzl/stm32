# Native build

Build your project with dependencies installed on your computer, which are available in your `$PATH`.  

---
Pros:  

* Easy to use  
* Ready for development with IDE  

Cons:

* Must install dependencies on your computer and have them be accessible in your `$PATH`
* Versions of packages differ wildly between different operating systems and distributions. It is hard for collaborative projects where all involved have different systems.  

Verdict:

* For the reasons above I recommend this option for individual development and solo release.  

---

## Dependencies

Install the following packages:

* git
* gnumake
* cmake
* gcc-arm-embedded (+ newlib and binutils if not included in the package)
* clang-tools (optional)

I would recommend gcc-10.3.y for latest C++20 features. Versions 9.x.y will still do C++20 but with a limited feature set. If you have newer, then go for it.  

You can download arm-none-eabi toolchain from [website](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads). It is universal for most distros. If your distribution carries it, install it with that, but mind the version and compatibility.  

**NOTE**. If your cmake fails to "compile a simple test program" while running the example, then you might not have `newlib` installed (one of the errors I have encountered). Some distribution packages carry the package separately.  

## Workflow

All actions are executed with the first part of the provided [Makefile](../Makefile).  
Following targets are available:  

`make -j<threads>`: build project.  
`make cmake`: (re)run cmake.  
`make build -j<threads>`: same as `make`.  
`make clean`: remove build folder.  

The included Makefile is used more as a helper script to avoid long repetitive commands. Plus you can add other useful targets, such as for formatting and flashing, where flashing part depends on a finished build. Quite nice.  

If you want to use `CMake` only, let's say for an IDE, then all you need to do is:  

* Generate cmake project (minimum):

    ```shell
    cmake -G "Unix Makefiles" -B build -DPROJECT_NAME=firmware -DCMAKE_TOOLCHAIN_FILE=gcc-arm-none-eabi.cmake -DCMAKE_BUILD_TYPE=Debug
    ```

* Compile project:

    ```shell
    # Directly with make
    make -C ./build -j<threads>

    # Indirectly with cmake
    cmake --build ./build -j<threads>
    ```

The indirect build command using cmake is convenient, as you don't need to know which build system is behind. CMake will call the one you have configured with first command. In this repository, this means `gnumake`.  
