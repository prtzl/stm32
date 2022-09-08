# Building with nix

Nix is a combination of package manager, source control, versioning and build tool. It uses a functional expression language to describe how to build a package. Using its repository store, `default.nix` file describes all the build inputs and outputs along with the build steps.  

Using, currently beta, flakes, we can improve the build step by providing a simple input and output definition of the project. On first build it will create a `flake.lock` file, which holds commit hashes for all used packages. This way, this project can be built at any time with the same exact version of software to provide the same exact binary.  

Nix has a steep learning curve, which I'm still in the middle of, but in the long run it proves to be very powerful and convenient. In one command, one can build an STM32 project, a x86_64 application and even mix the two, to provide a certain output. Flashing and building can also be automated.  

## Dependencies

Nix can be install on all unix platforms. Navigate the [website](https://nixos.org/download.html) for installation instructions. For current flakes we'll need the most up-to date version on `unstable` channel.  

You can also install `direnv` to your shell along with `nix-direnv` and run `direnv allow` to automatically load the shell with installed dependencies. Otherwise call `nix develop`. This enables you to enter a shell with all the packages that are used to build you project and more. This is very useful for development and debugging without the need to install the packages on your computer globally.  

## Workflow

To build the project, run

```shell
nix build # optionaly add -L to see the progress
```

Default target is currently set to be the firmware.  
If successful, the resulting `.bin`, `.elf` and `.s` files will be placed into symlink directory `./result/bin`.  

To flash the firmware you can currently use stlink or jlink. The run command depends on firmware, which will be built if missing or if the source files have been changed.

```shell
# Default run target - currently jlink
nix run

# Run jlink flasher
nix run .#flash-jlink

# Run stlink flasher
nix run .#flash-stlink
```

If you're using `nix-direnv`, then the first time you load up the development shell it will download all the inputs and create a cache directory `.direnv`. As long as this directory remains, nix garbage collector won't touch it. You can see the link for all such repositories in `/nix/var/nix/gcroots`, where the exsistance of a link signals nix garbage collector to leave the repository sources alone.  

In development mode use the provided [Makefile](../Makefile) as described in [native development](build-native.md), which generates build files along with `compile_commands.json` in `build` folder. You can use this in your IDE of choice. You can also use nix to generate those files, but make sure, that your IDE was launched from the development shell or, in case of vscode, you have nix plugins installed.  

---

Pros:  

* Dependencies are not installed system-wide and do not pollute your filesystem.  
* Project dependencies version is fixed with lock file and only updates on users request.  
* You can still use the provided [Makefile](../Makefile) as with [native development](build-native.md) as the shell loads all the dependencies.  
* For the above reason, you can also use your favorite IDE.  

Cons:  

* Steep learning curve with nix expression language.  
* Not available natively on windows.  

Verdict:

* For the reasons above I recommend this option for everyone running linux or macOS for development and release.  

---
