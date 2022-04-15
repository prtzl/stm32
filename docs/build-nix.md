# Building with nix

Nix is a combination of package manager, source control, versioning and build tool. It uses a functional expression language to describe how to build a package. Using its repository store, `default.nix` file describes all the build inputs and outputs along with the build steps.  

Using, currently beta, flakes, we can improve the build step by providing a simple input and output definition of the project. On first build it will create a `flake.lock` file, which holds commit hashes for all used packages. This way, this project can be built at any time with the same exact version of software to provide the same exact binary.  

Nix has a steep learning curve, which I'm still in the middle of, but in the long run it proves to be very powerful and convenient. In one command, one can build an STM32 project, a x86_64 application and even mix the two, to provide a certain output. Flashing and building can also be automated.  

## Dependencies

Nix can be install on all unix platforms. For current flakes we'll need the most up-to date version on `unstable` channel.  

You can also install `direnv` to your shell along with `nix-direnv` and run `direnv allow` to automatically load the shell with installed dependencies. Otherwise call `nix develop`. This enables you to create a shell with all the packages, that are used to build you project, and more. This is very useful for development and debugging.  

## Workflow

To build the project, run `nix build`. If successful, the resulting `.bin`, `.elf` and `.s` files will be placed into symlink directory `result`. *Not 100% sure: As long as this link is in the project, nix garbage collector will not remove the project derivation, which can be problematic if you have a slower connection or you are offline.*  

In development mode use the provided [Makefile](Makefile) as described in [native development](#native), which generates build files along with `compile_commands.json` in `build` folder. You can use this in your IDE of choice. You can also use nix to generate those files, but make sure, that your IDE was launched from the development shell or, in case of vscode, you have nix plugins installed.  

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
