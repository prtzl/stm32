project('stm32', ['c', 'cpp'], default_options : ['optimization=g', 'debug=true'])

assert(meson.get_compiler('c').get_id() == 'gcc')

## Compiler options
c_args = []
c_args += '-mcpu=@0@'.format(host_machine.cpu())
c_args += '-mfpu=fpv4-sp-d16'
c_args += '-mfloat-abi=hard'
c_args += '-DSTM32F407xx'
c_args += '-DUSE_HAL_DRIVER'

c_args += '-g3'
c_args += '-ggdb3'
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

linkfile = 'CubeMX/STM32F407VGTx_FLASH.ld'
link_args += '-T@0@/@1@'.format(meson.current_source_dir(), linkfile)

if meson.get_compiler('c').version() > '10.3.1'
  link_args += '-Wl,--no-warn-rwx-segments'
endif

# For some reason, c_link_args from cross file is not used, why??
link_args += ['-mthumb', '--specs=nano.specs', '-ffunction-sections', '-fdata-sections', '-Wl,--gc-section']

## STM32 sources and headers
stm32cube_incdirs = []
stm32cube_incdirs += include_directories('Drivers/CMSIS/Device/ST/STM32F4xx/Include', is_system : true)
stm32cube_incdirs += include_directories('Drivers/STM32F4xx_HAL_Driver/Inc', is_system : true)
stm32cube_incdirs += include_directories('Drivers/CMSIS/Include', is_system : true)
stm32cube_incdirs += include_directories('Drivers', is_system : true)
stm32cube_incdirs += include_directories('Core/Inc', is_system : true)

stm32cube_srcs = []
startupfile = 'CubeMX/startup_stm32f407xx.s'
stm32cube_srcs += startupfile

stm32cube_srcs += 'Core/Src/gpio.c'
stm32cube_srcs += 'Core/Src/main.c'
stm32cube_srcs += 'Core/Src/stm32f4xx_hal_msp.c'
stm32cube_srcs += 'Core/Src/stm32f4xx_it.c'
stm32cube_srcs += 'Core/Src/system_stm32f4xx.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma_ex.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_exti.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ex.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ramfunc.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_gpio.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr_ex.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc_ex.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim.c'
stm32cube_srcs += 'Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim_ex.c'

incdirs = []
incdirs += ['Project']

srcs = []
srcs += ['Project/SWO.c']
srcs += ['Project/projectMain.cpp']

## Output targets
# Main target
main = executable(
  'main',
  [srcs, stm32cube_srcs, startupfile],
  name_suffix : 'elf',
  c_args : [c_args, '-std=c11'],
  cpp_args : [cpp_args, '-std=c++20'],
  link_args : link_args,
  dependencies : [],
  include_directories : [incdirs, stm32cube_incdirs])

# Post-build targets
objcopy  = '@0@'.format(find_program('objcopy').path())
objdump  = '@0@'.format(find_program('objdump').path())
size     = '@0@'.format(find_program('size').path())

# binary
mainbin = custom_target(
                      'main.bin',
  output           : ['main.bin'],
  build_by_default : true,
  command          : [objcopy, '-O', 'binary', 'main.elf', 'main.bin'],
  depends          : [main])

# Size output
# text = all RO segments (.text, .isr_vector, .rodata, .ARM)
# data = all RW segments (.data)
# .bss = all runtime RW segemnts (.bss, .heap)
mainsize = custom_target(
                    'size',
  capture          : false,
  output           : ['main.size'],
  build_by_default : true,
  command          : [size, '--format=berkely', 'main.elf'],
  depends          : [main])

# objdump
maindump = custom_target(
                    'dump',
  capture          : true,
  output           : 'main.dump',
  build_by_default : false,
  command          : [objdump, '-D', '-S', '-t', 'main.elf'],
  depends          : [main])
