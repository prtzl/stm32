# STM32 project template

This repository holds all the possible tools and templates for building and developing STM32 projects.  
Project is configured with CMake and can be built with multiple ways.  

I don't expect you to use all of the files found here or all the lines in the configuration files (Makefile, CMakeLists.txt, etc.), so make sure to remove all that you don't need for your project.  

I will also try to make this repository as cross platform as possible.  

## Example

You can utilize everything in root of the repository. It holds an example project built around `STM32F407VG`.

## Workflow

You have a few options to build your project. Pros and cons will be listed for each method in its guide.  

[First way](docs/build-native.md) is to use the provided [Makefile](Makefile) for native development on your computer, but you have to install the required dependencies on your computer, matching or exceeding the minimum required versions.  

[Second way](docs/build-container.md) is using a container tool like `docker` or `podman` with or without additional dependencies, like `docker-compose` or `make`.  

[Third way](docs/build-nix.md) is using nix with provided `flake.nix`.  

## Code style

Before committing code, format all source files. I have provided a set of rules for `clang-format`, which you can apply to all source files.  

You can do it by hand: `clang-format -i <path to source file>`  

Or with a shell script:  

```shell
for file in $(find . -name '*.[ch]' -or -name '*.[ch]pp'); do clang-format -i $file; done
```

Or with provided makefile:

`make format`: formats all source files in root using host computer.  
`make format-container`: formats all source files in root using container.  

## Extra tool tips

I have provided a [document](docs/tools.md), where I write about tools and commands that you can use to aid your development.  
