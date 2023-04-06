project('stm32', ['c', 'cpp'], default_options : ['optimization=g', 'debug=true'])

srcs = []
incdirs = []
c_args = []
cpp_args = []
link_args = []
link_deps = []

c_args += '-DSTM32F407xx'
c_args += '-DUSE_HAL_DRIVER'
c_args += '-mfpu=fpv4-sp-d16'
c_args += '-mfloat-abi=hard'
linkfile = 'CubeMX/STM32F407VGTx_FLASH.ld'
startupfile = 'CubeMX/startup_stm32f407xx.s'

cpu = host_machine.cpu()
c_args += '-mcpu=@0@'.format(cpu)
c_args += '-ggdb3'

arch = 'armv7e-m'

# link_deps += meson.get_compiler('c').find_library()

link_args += ['-T@0@/@1@'.format(meson.current_source_dir(), linkfile)]

stm32cube_srcs = []
stm32cube_incdirs = []

stm32cube_incdirs += include_directories('Drivers/CMSIS/Device/ST/STM32F4xx/Include', is_system : true)
stm32cube_incdirs += include_directories('Drivers/STM32F4xx_HAL_Driver/Inc', is_system : true)
stm32cube_incdirs += include_directories('Drivers/CMSIS/Include', is_system : true)
stm32cube_incdirs += include_directories('Drivers', is_system : true)
stm32cube_incdirs += include_directories('Core/Inc', is_system : true)

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

incdirs += include_directories('/nix/store/7026gggbzcvj6bvbdcm68z665ngd3d7k-gcc-arm-embedded-12.2.rel1/arm-none-eabi/include/c++/12.2.1', is_system : true)
incdirs += include_directories('/nix/store/7026gggbzcvj6bvbdcm68z665ngd3d7k-gcc-arm-embedded-12.2.rel1/arm-none-eabi/include/newlib-nano', is_system : true)

message('hrenovka')
message('@0@'.format(c_args))

# if meson.get_cross_property('newlib_nano') == true
  # message('newlib_nano added')
  # linkDeps +=  meson.get_compiler('c').find_library('/usr/lib/arm-none-eabi/newlib/libc_nano')
  # linkDeps +=  meson.get_compiler('c').find_library('/usr/lib/arm-none-eabi/newlib/librdimon_nano')
  # linkDeps +=  meson.get_compiler('c').find_library('/usr/lib/arm-none-eabi/newlib/libg_nano')
  # linkDeps +=  meson.get_compiler('c').find_library('/usr/lib/arm-none-eabi/newlib/libstdc++_nano')
  # linkDeps +=  meson.get_compiler('c').find_library('/usr/lib/arm-none-eabi/newlib/libsupc++_nano')
  #
  # linkDeps +=  meson.get_compiler('c').find_library('/usr/lib/arm-none-eabi/newlib/libm')
  # linkDeps +=  meson.get_compiler('c').find_library('/usr/lib/arm-none-eabi/newlib/libnosys')
# endif

link_args += c_args
link_args += '-Wl,-Map=main.map'

link_args += ['-mthumb','-fshort-enums','-fmessage-length=0','-fsigned-char','-ffunction-sections','-fdata-sections','-Wall','--specs=nano.specs','-Wl,--gc-sections']

main = executable(
  'main',
  [srcs, stm32cube_srcs, startupfile],
  name_suffix : 'elf',
  c_args : [c_args, '-std=c11'],
  cpp_args : [c_args, cpp_args, '-std=c++20'],
  link_args : link_args,
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
