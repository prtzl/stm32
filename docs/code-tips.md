# Code tips

This document includes various tips and options for writing and debugging code. Some of the entries are less used tools, that might be annoying to google every time I need them. This document is a common place for those as well.

## Pragmas

`#pragma` is a directive specifying extra information to the compiler. With it you can print debug messages, change compilation warnings and optimizations and much more.  

You might be familiar with `pragma once`, which lets the compiler know to only read the file once. It is usually found on top of header files. This is so called "un-official" replacement for include guard for preventing the same header file to be included multiple times.

```c
// header file
#ifndef HEADER_FILE_H
#define HEADER_FILE_H

// contents of header file

#endif
```

The old method requires that the programmer does provide a unique macro for each header file. Pragma on the other hand is trivial.  

Include errors, resulting in some form of re-definition, is caused by the header being included by other header files, which are then in turn included in a source file - thus multiple inclusions of the same header file.  

`#pragma` in itself is part of the C and C++ standard, but `#pragma once` is part of the compiler implementation, therefore it is not as universal as `#ifndef` include guards, which are based on the preprocessor standard. Still it is widely adopted in most modern compilers.

The syntax for a pragma might look something like this:

```c
#pragma PREFIX option value(s)
```

Pragma can source its rules and options from various packages. Those defined by the standard use a prefix `STDC`, while those used by GNU use `GCC` prefix.  

### Option stacking

It is important to note, that a pragma directive applies for the whole file from that point. Everything before it is unaffected. This is why, when applying certain options just for a small section, it is useful to save current options and restore them back after the said section.  

This is why you should use `push` and `pop` options before and after applying a pragma. Push and pop can be used as a value to an option or as part of the option as well. Here are a few examples

```c
#pragma GCC diagnostic push
#pragma GCC diagnostic error "-Wformat" // treat this warning as error

// section affected by 
void foo()
{
    ...
}

#pragma GCC diagnostic pop
```

```c
#define MACRO 1
#pragma GCC push_macro("MACRO") // save MACRO value to stack
#undef MACRO // undefine macro MACRO

// section affected by 
void foo()
{
    ...
}

#pragma GCC pop_macro("MACRO") // pop value of macro MACRO back
```

## Code optimization

For most scenarios, I stand by a rule to use the same optimization options for both `Debug` and `Release` builds. This prevents unnecessary errors and code breakage when switching builds types, where optimizer might do a too-good job and it ends up breaking the executable. Remember, build type is not just about optimization level.  

For my builds, as well as this template, I use option `Og` for `gcc` compiler. This is, by my estimations, the best compromise between optimized code and debug-ability. However it still isn't perfect. While it does prevent inlining of regular functions, some lambdas and trivial class methods do get inlined. Sometimes whole `if-else` blocks get optimized to a point, that you cannot put a breakpoint anywhere useful. Even if you do, some variables might get optimized and debugger will not be able to give you any information on their value.  

You can change the level of optimization for a whole section of functions with a pragma.  

```c
#pragma GCC push_options // save current compiler options
#pragma GCC optimize ("-O0") // set optimization level to zero

void foo(int a)
{
    int cpy = a;
    return cpy + 5;
}

#pragma GCC pop_options // restore saved compiler options
```

In the example above, such trivial function might get optimized away. If not, stepping through it might prove useless, as variable `cpy` might get optimized so that debugger cannot see its value. Setting optimization level to zero disables any funny business from the compiler and forces it to generate expected instructions.

## System headers and warnings

While inspecting compiler output when building your project, you might find that some header file paths include `-isystem` option right before. Also, in my CMake project template, I call `target_include_directories` twice. One includes `CubeMX` drivers only and has an extra `SYSTEM` option, while other includes all user generated code without the extra option. This `SYSTEM` options generates `-isystem` argument for the compiler before giving it a include path. What's up with that?  

In short, system paths are already pre-determined by the compiler and it's the reason, why you can just `#include <stdio.h>` and the compiler will find the file. It has a set of system paths where it will look for the library first. But there is more.  
Because such libraries might be old and/or cross platform, some *harmless* errors might be produced. If you were to use them on your project, you might get tons and tons of useless errors coming from the library and not your code. This is why system libraries get special treatment. This is why **ALL** warnings, other then `#warning` *ARE IGNORED*.  

The case of vendor provided libraries is much the same. They might not be developed with such strict error checking as your project; which I advise. C++ warnings regarding casting `-Wuseless-cast` and `-Wold-style-cast` dominate the warning output (try removing `SYSTEM` from include directory for CubeMX and see the output). Specifying CubeMX headers as system clears them of useless errors and allows us to use strict error checking on user code without affecting system libraries.  
