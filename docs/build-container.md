# Building STM32 project with Container

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

## Dependencies

Install docker or podman (linux only). Docker desktop will also install some tools, like `docker-compose`. In next steps, you will also have an option to use some additional dependencies for certain workflows.

## With Makefile

You can use the same [Makefile](Makefile) to build container image and your project, which requires you to also install `make`. The following targets are available:  

`make build-container`: (build) the container image, run container to build project using container.  
`make image`: (re)build the container image.  
`make shell`: run container and connect to shell, exit with `Ctrl+D` or `exit` command.  
`make clean-image`: remove container and image.  
`make clean-all`: remove build folder, remove container, remove image.  

Default container manager is [docker](https://www.docker.com/). Everything is also compatible with [podman](https://podman.io/) as the syntax is mostly the same. You can read on the differences between the two [here](https://phoenixnap.com/kb/podman-vs-docker).  

Run `<docker/podman> container prune` and enter `y` to remove any leftover containers.  

## With compose

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

## With just the container

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

If you're using `podman`, then you also have to provide a few more arguments to  **run** commands: `--userns=keep-id --security-opt label=disable`.  

**NOTE:** building in container with makefile on Windows 10 is currently not working, use [docker-compose](#with-compose).  
Tested with docker (`20.10.9`), podman (`3.4.3`), docker-compose (`1.29.2`) on Fedora 35.  
