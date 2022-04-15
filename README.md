# STM32 project template with CMake

This repository holds all the possible tools for developing STM32 projects. Root of the repository also represents an example project for `STM32F407VG`.  
Project is configured with CMake and can be built with multiple ways.  

I don't expect you to use all of the files found here or all the lines in the configuration files (Makefile, CMakeLists.txt, etc.), so make sure to remove all that you don't need for your project.  

I will also try to make this repository as cross platform as possible.  

## Dependencies

For native development on your computer install the following packages:

* git
* gnumake
* cmake
* gcc-arm-embedded
* clang-tools (optional)

I would recommend gcc-10.3.y for latest C++20 features. Versions 9.x.y will still do C++20 but with a limited feature set. If you have newer, then go for it.  

You can download arm-none-eabi toolchain from [website](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads). It is universal for most distros. If your distribution carries it, install it with that, but mind the version and compatibility.  

**NOTE**. If your cmake fails to "compile a simple test program" while running the example, then you might not have `newlib` installed (one of the errors I have encountered). Some distribution packages carry the package separately.

For other methods refer to the [workflow](#workflow) chapters.  

## Example

You can utilize everything in root of the repository. It holds an example project built around `STM32F407VG`.

## Workflow

You have a few options to build your project. Pros and cons will be listed for each method in its sub-chapter.  

[First way](#native) is to use the provided [Makefile](Makefile) for native development on your computer, but you have to install the required dependencies on your computer, matching or exceeding the minimum required versions.  

[Second way](#container) is using a container tool like `docker` or `podman` with or without additional dependencies, like `docker-compose` or `make`.  

[Third way](#nix) is using nix with provided `flake.nix`.  

## Native

All actions are executed with the first part of the provided [Makefile](Makefile).  

Following targets are available:  

`make -j<threads>`: build project.  
`make cmake`: (re)run cmake.  
`make build -j<threads>`: same as `make`.  
`make clean`: remove build folder.  

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

## Container

For reproducible development environment use the provided [container](Dockerfile). It installs the latest gcc-arm-embedded toolchain from ARMs website which guarantees the same version every time. Other (less version critical) packages are installed via distribution package manager. Appropriate distribution is chosen, which holds packages with at least minimum required version in the repositories.  

---
Pros:  

* Minimal dependencies, only container tool and possibly `make` or `-compose`.  
* Low file system pollution.
* Cross platform and cross distribution (except with podman).  

Cons:  

* Since all dependencies and tools are installed in the container, IDEs will not be able to find the libraries.  

Verdict:  

* For the reason above I recommend this method for creating release in collaborative and solo projects.  

---

### With Makefile

You can use the same [Makefile](Makefile) to build container image and your project, which requires you to also install `make`. The following targets are available:  

`make build-container`: (build) the container image, run container to build project using container.  
`make image`: (re)build the container image.  
`make shell`: run container and connect to shell, exit with `Ctrl+D` or `exit` command.  
`make clean-image`: remove container and image.  
`make clean-all`: remove build folder, remove container, remove image.  

Default container manager is [docker](https://www.docker.com/). Everything is also compatible with [podman](https://podman.io/) as the syntax is mostly the same. You can read on the differences between the two [here](https://phoenixnap.com/kb/podman-vs-docker).  

Run `<docker/podman> container prune` and enter `y` to remove any leftover containers.  

### With compose

There is also a `docker-compose.yml`, which you can use if you don't have(want) `make` installed, but you will need `docker-compose`. Docker for windows already installs it.  

First build the image:

```shell
docker-compose build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg USERNAME=$(id -un) --build-arg GROUPNAME=$(id -gn) container
```

On windows replace GROUPNAME parameter with username `GROUPNAME=$(id -un)`.  

There are several services for the `docker-compose`, which are analog to Makefile targets:  

`docker-compose run stmbuild`: build the project  
`docker-compose run stmrebuild`: rebuild the project  
`docker-compose run stmclean`: clean the project  
`docker-compose run shell`: connect to container shell  

Run `docker-compose down` after you're done to remove containers.  

**NOTE:** Syntax for `podman-compose` is similar to `docker-compose`, but as of now I'm having problems running the services the same way as with `docker-compose`.  

### With just the container

First build the image:

```shell
docker build -t fedora-arm-embedded-dev --build-arg UID=`id -u` --build-arg GID=`id -g` --build-arg USERNAME=`id -un` --build-arg GROUPNAME=`id -gn` .
```

On windows replace GROUPNAME parameter with username `GROUPNAME=$(id -un)`.  

Build the project:

```shell
# Linux
docker run --rm -it -v "$(pwd):/workdir" -w/workdir fedora-arm-embedded-dev bash -lc "make -j8"

# Windows
winpty docker run --rm -it -v "/$(pwd -W):/workdir" -w//workdir fedora-arm-embedded-dev bash -lc "make -j8"

```

Clean project:

```shell
# Linux
docker run --rm -it -v "$(pwd):/workdir" -w/workdir fedora-arm-embedded-dev bash -lc "make clean"

# Windows
winpty docker run --rm -it -v "/$(pwd -W):/workdir" -w//workdir fedora-arm-embedded-dev bash -lc "make clean"
```

Connect to a container shell:

```shell
# Linux
docker run --rm -it -v "$(pwd):/workdir" -w/workdir fedora-arm-embedded-dev bash -l

# Windows
winpty docker run --rm -it -v "/$(pwd -W):/workdir" -w//workdir fedora-arm-embedded-dev bash -l
```

**NOTE:** building in container with makefile on Windows 10 is currently not working, use [docker-compose](#with-compose).  
Tested with docker (`20.10.9`), podman (`3.4.3`), docker-compose (`1.29.2`) on Fedora 35.  

## Nix

Provided [flake.nix](flake.nix) pulls required dependencies with a fixed version by the [flake.lock](flake.lock) file. If you have installed `direnv` to your shell along with `nix-direnv`, run `direnv allow` to automatically load the shell with installed dependencies. Otherwise call `nix develop`.  

To build the project, run `nix build`. If successful, the resulting `.bin`, `.elf` and `.s` files will be placed into symlink directory `result`. *Not 100% sure: As long as this link is in the project, nix garbage collector will not remove the project derivation, which can be problematic if you have a slower connection or you are offline.*  

In development mode use the provided [Makefile](Makefile) as described in [native development](#native), which generates build files along with `compile_commands.json` in `build` folder. You can use this in your IDE of choice.  

---

Pros:  

* Dependencies are not installed system-wide and do not pollute your file system.  
* Project dependencies version is fixed with lock file and only updates on users request.  
* You can still use the provided [Makefile](Makefile) as with [native development](#native) as the shell loads all the dependencies.  
* For the above reason, you can also use your favorite IDE.  

Cons:  

* Steep learning curve with nix expression language.  
* Not available natively on windows.  

Verdict:

* For the reasons above I recommend this option for everyone running linux or macOS for development and release.  

---

## Code style

Before committing code, format all source files. I have provided a set of rules for `clang-format`, which you can apply to all source files.  

You can do it by hand:  

```shell
for file in $(find . -name '*.[ch]' -or -name '*.[ch]pp'); do clang-format -i $file; done
```

`make format`: formats all source files in root using host computer.  
`make format-container`: formats all source files in root using container.  
