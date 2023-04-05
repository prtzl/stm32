project('stm32', ['c', 'cpp'])

srcs = []
incdirs = []
c_args = []
cpp_args = []
link_args = []
link_deps = []

c_args += '-DSTM32F407xx -DUSE_HAL_DRIVER'
linkfile = 'CubeMX/STM32F407VGTx_FLASH.ld'
startupfile = files(['CubeMX/startup_stm32f407xx.s'])

cpu = host_machine.cpu()
c_args += '-mcpu=@0@'.format(cpu)
c_args += '-O3'
cpp_args += '-O3'

arch = 'armv7e-m'

# link_deps += meson.get_compiler('c').find_library()

link_args += ['-Wl,-T,@0@/@1@'.format(meson.current_source_dir(), linkfile)]

stm32cube_srcs = []
stm32cube_incdirs = []

stm32cube_incdirs += include_directories('Drivers/CMSIS/Device/ST/STM32F4xx/Include')
stm32cube_incdirs += include_directories('Drivers/STM32F4xx_HAL_Driver/Inc')
stm32cube_incdirs += include_directories('Drivers/CMSIS/Include')
stm32cube_incdirs += include_directories('Drivers')
stm32cube_incdirs += include_directories('Core/Inc')

stm32cube_srcs += ['Core/Src/gpio.c']
stm32cube_srcs += ['Core/Src/main.c']
stm32cube_srcs += ['Core/Src/stm32f4xx_hal_msp.c']
stm32cube_srcs += ['Core/Src/stm32f4xx_it.c']
stm32cube_srcs += ['Core/Src/system_stm32f4xx.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma_ex.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_exti.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ex.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ramfunc.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_gpio.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr_ex.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc_ex.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim.c']
stm32cube_srcs += ['Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim_ex.c']

incdirs += ['Project']

srcs += ['Project/SWO.c']
srcs += ['Project/projectMain.cpp']

main = executable(
  'main',
  [srcs, stm32cube_srcs, startupfile],
  name_suffix : 'elf',
  c_args : [c_args, '-std=c11'],
  cpp_args : [c_args, cpp_args, '-std=c++20'],
  link_args : [link_args, '--specs=nosys.specs'],
  dependencies : link_deps,
  include_directories : [incdirs, stm32cube_incdirs]
  )

objcopy  = '@0@'.format(find_program('objcopy').path())
objdump  = '@0@'.format(find_program('objdump').path())
size     = '@0@'.format(find_program('size').path())

mainbin = custom_target(
                        'main.bin',
    output           : ['main.bin'],
    # name_suffix      : 'bin',
    build_by_default : true,
    command          : [objcopy, '-O', 'binary', 'main.elf', 'main.bin'],
    depends          : [main])

mainsize = custom_target(
                          'size',
        capture          : true,
        output           : ['main.size'],
        build_by_default : true,
        command          : [size, '--format=berkeley', 'main.elf'],
        depends          : [main])

if meson.get_compiler('c').get_id() == 'gcc'
  maindump = custom_target(
                        'dump',
      capture          : true,
      output           : 'main.dump',
      build_by_default : false,
      command          : [objdump, '-D', '-S', '-t', 'main.elf'],
      depends          : [main])
endif
