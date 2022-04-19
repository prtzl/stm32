# Usefull build tools

This documents includes some useful tools and how to use them for development and debugging.  

Most of these tools print output in terminal, which can be problematic if the output is large or you want to save it.  

For inspecting the contents and discarding the result I just pipe the output into less:  

```shell
<command> <options> <input file> | less
```

For saving file, you can redirect the output into a new file:  

```shell
<command> <options> <input file> > outputFile.txt
```

**NOTE:** `>` redirection will overwrite the file. If you want to append to it, use `>>`.

## objdump

This tool is used to view contents of object files, such as `.o` and `.elf`.The arm toolchain provides `arm-none-eabi-objdump`.  

In context of executable `.elf`, this can be used to disassemble a section or the entire file. With this tool you can inspect the assembly and state of sections and variables.  

Command:

```shell
arm-none-eabi-objdump <options> <file.[elf/o]>
```

Options:

* `-d`: disassemble all "runnable" sections (code)  
* `-D`: disassemble all sections (code and data)  
* `-j <section name>`: used along with `-d/D` will display only a selected section  
* `-C`: demangle symbol names (C++)  
* `-h`: view only headers (used alone without other options)  

### Examples

**Dump a specific section (example: .rodata):**

```shell
arm-none-eabi-objdump -D -j .rodata -C ./firmware.bin
```

**Dump the entire file:**

```shell
arm-none-eabi-objdump -D -C ./firmware.bin
```

**View section headers:**

```shell
arm-none-eabi-objdump -h ./firmware.bin
```

## readelf

This tool is similar in function to `objdump` but displays a bit more information. It is also limited to `.elf` files. The arm toolchain provides `arm-none-eabi-readelf`.  

Command:

```shell
arm-none-eabi-readelf <options> <file.elf>
```

Options:

* `-h`: display ELF file header (file information)  
* `-S`: display sections (a bit nicer than `objdump -h`, but missing some information)  
* `-s`: display all symbols (functions)
* `-C`: demangle symbol names (C++), used with `-s`
* `-x <section name>`: hexdumps the section contents
* `-p <section name>`: stringdumps the section contents

### Examples

**View file information:**

```shell
arm-none-eabi-readelf -h ./firmware.elf
```

**View sections headers:**

```shell
arm-none-eabi-readelf -S -C ./firmware.elf
```

**View all symbols:**

```shell
arm-none-eabi-readelf -s -C ./firmware.elf
```

**Hexdump section:**

```shell
arm-none-eabi-readelf -x .rodata ./firmware.elf
```

**Stringdump section:**

```shell
arm-none-eabi-readelf -p .rodata ./firmware.elf
```

## hexdump

Hexdump is used to view and filter raw contents of a file. The output format can be changed. The utility is not specific to arm toolchain and can be found on most linux distributions already installed.  

It doesn't do much, therefore it doesn't have as many options, so I use it mainly for viewing bin files:  

```shell
hexdump -C <file.bin>
```

This command will display output in hex as well as ascii (similar to objdump with `-x`).  
