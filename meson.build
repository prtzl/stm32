project('firmware', ['c', 'cpp'], default_options : ['optimization=g', 'debug=true'], version : files('VERSION'))


## STM32 platform vars
stm32_family = 'STM32F4xx'
stm32_model  = 'STM32F407xx'
stm32_fpu    = 'fpv4-sp-d16'

## STM32 sources and headers
# This allows checking if file exists - throws if not
# I could also implement this where used, but since it throws here, looks better?
startupfile = files('CubeMX/startup_stm32f407xx.s')[0]
linkfile = files('CubeMX/STM32F407VGTx_FLASH.ld')[0]

# Default (usually STM32 core directories)
stm32cube_incdirs = []
stm32cube_incdirs += include_directories('Drivers/CMSIS/Device/ST/@0@/Include'.format(stm32_family), is_system : true)
stm32cube_incdirs += include_directories('Drivers/@0@_HAL_Driver/Inc'.format(stm32_family), is_system : true)
stm32cube_incdirs += include_directories('Drivers/@0@_HAL_Driver/Inc/Legacy'.format(stm32_family), is_system : true)
stm32cube_incdirs += include_directories('Drivers/CMSIS/Include', is_system : true)
stm32cube_incdirs += include_directories('Drivers', is_system : true)
stm32cube_incdirs += include_directories('Core/Inc', is_system : true)

# Project include directories
incdirs = []
incdirs += ['Project']

# Project sources - we'll use glob for our project
srcs = []
srcs += startupfile

# Glob is not evil, just re-invoke meson (or add file to the list, same amount of work to me :P)
glob = run_command('glob.sh', check : true).stdout().strip().split('\n')
srcs += glob

########################### GOIN TO WORK ? ####################################

assert(meson.get_compiler('c').get_id() == 'gcc')

## Compiler options
c_args = []
c_args += '-mcpu=@0@'.format(host_machine.cpu())
if stm32_fpu != ''
  c_args += '-mfpu=@0@'.format(stm32_fpu)
  c_args += '-mfloat-abi=hard'
else
  c_args += '-mfloat-abi=soft'
endif
c_args += '-D@0@'.format(stm32_model)
c_args += '-DUSE_HAL_DRIVER'

# TODO: if it with debug?
c_args += '-g3'
c_args += '-ggdb'

c_args += '-Wall'
c_args += '-Wextra'
c_args += '-Wpedantic'
c_args += '-Wshadow'
c_args += '-Wdouble-promotion'
c_args += '-Wformat=2'
c_args += '-Wformat-truncation'
c_args += '-Wundef'
c_args += '-fno-common'
c_args += '-Wno-unused-parameter'
c_args += '-fdiagnostics-color=always'

cpp_args = []
cpp_args += c_args
cpp_args += '-Wconversion'
cpp_args += '-Wno-volatile'
cpp_args += '-Wold-style-cast'
cpp_args += '-Wuseless-cast'
cpp_args += '-Wsuggest-override'

## Linker options
link_args = []
link_args += c_args
link_args += '-Wl,-Map=main.map '
link_args += '-Wl,--print-memory-usage'
# So, linker wants a full path to the file
link_args += '-T@0@/@1@'.format(meson.current_source_dir(), linkfile)

if meson.get_compiler('c').version() > '10.3.1'
  link_args += '-Wl,--no-warn-rwx-segments'
endif

## Output targets

pname = meson.project_name()
pexe = pname + '.elf'
pbin = pname + '.bin'
phex = pname + '.hex'
psize = pname + '.size'
pdump = pname + '.s'

# Main target
main = executable(
                        pname,
                        [srcs],
                        name_suffix : 'elf',
  c_args              : [c_args, '-std=c11'],
  cpp_args            : [cpp_args, '-std=c++20'],
  link_args           : link_args,
  dependencies        : [],
  include_directories : [incdirs, stm32cube_incdirs])

# Post-build targets
objcopy  = '@0@'.format(find_program('objcopy').path())
objdump  = '@0@'.format(find_program('objdump').path())
size     = '@0@'.format(find_program('size').path())

# binary
mainbin = custom_target(
                     pbin,
  output           : [pbin],
  build_by_default : true,
  command          : [objcopy, '-O', 'binary', pexe, pbin],
  depends          : [main])

# Size output
# text = all RO segments (.text, .isr_vector, .rodata, .ARM)
# data = all RW segments (.data)
# .bss = all runtime RW segemnts (.bss, .heap)
mainsize = custom_target(
                    'size',
  capture          : false,
  output           : [psize],
  build_by_default : true,
  command          : [size, '--format=berkely', pexe],
  depends          : [main])

# objdump
maindump = custom_target(
                    'dump',
  capture          : true,
  output           : pdump,
  build_by_default : false,
  command          : [objdump, '-D', '-S', '-t', pexe],
  depends          : [main])
