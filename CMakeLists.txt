# STM32 Minimal CMake project for C/C++ projects
cmake_minimum_required(VERSION 3.12)
###############################################################################

include(./gcc-arm-none-eabi.cmake)

# Set debug mode as default
if ("${CMAKE_BUILD_TYPE}" STREQUAL "")
  set(CMAKE_BUILD_TYPE debug)
endif()
message("Build type: ${CMAKE_BUILD_TYPE}")

# Set project name and some defaults
if ("${PROJECT_NAME}" STREQUAL "")
  set(PROJECT_NAME firmware)
endif()
if ("${PROJECT_VERSION}" STREQUAL "")
  set(PROJECT_VERSION 1.0)
endif()

project("${PROJECT_NAME}-${CMAKE_BUILD_TYPE}-${PROJECT_VERSION}")

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set microcontroller information
set(MCU_FAMILY STM32F4xx)
set(MCU_MODEL STM32F407xx)
set(CPU_PARAMETERS
  -mcpu=cortex-m4
  -mthumb
  -mfpu=fpv4-sp-d16
  -mfloat-abi=hard)

set(STARTUP_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/CubeMX/startup_stm32f407xx.s)
set(MCU_LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/CubeMX/STM32F407VGTx_FLASH.ld)

###############################################################################
enable_language(C CXX ASM)
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
set(CMAKE_CXX_EXTENSIONS ON)

###############################################################################
set(STM32CUBEMX_INCLUDE_DIRECTORIES
  ${CMAKE_CURRENT_SOURCE_DIR}/Core/Inc
  ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/${MCU_FAMILY}_HAL_Driver/Inc
  ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/${MCU_FAMILY}_HAL_Driver/Inc/Legacy
  ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Device/ST/${MCU_FAMILY}/Include
  ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Include
)

set(PROJECT_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR})

file(GLOB_RECURSE STM32CUBEMX_SOURCES CONFIGURE_DEPENDS
  ${CMAKE_CURRENT_SOURCE_DIR}/Core/*.c
  ${CMAKE_CURRENT_SOURCE_DIR}/Drivers/*.c
)

set(PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Project)
file(GLOB_RECURSE PROJECT_SOURCES CONFIGURE_DEPENDS
  ${PROJECT_DIR}/*.cpp
  ${PROJECT_DIR}/*.c
)

add_executable(${CMAKE_PROJECT_NAME}
  ${STM32CUBEMX_SOURCES} 
  ${PROJECT_SOURCES}
  ${STARTUP_SCRIPT}
)

target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
  #$<$<CONFIG:debug>:DEBUG>
  ${MCU_MODEL}
  USE_HAL_DRIVER
)

target_include_directories(${CMAKE_PROJECT_NAME} SYSTEM PRIVATE
  ${STM32CUBEMX_INCLUDE_DIRECTORIES}
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
  ${PROJECT_INCLUDE_DIRECTORIES}
)

###############################################################################
target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE
  ${CPU_PARAMETERS}
  -Wall
  -Wextra
  -Wpedantic
  -Wshadow
  -Wdouble-promotion
  -Wformat=2 -Wformat-truncation
  -Wundef
  -fno-common
  -Wno-unused-parameter
  $<$<COMPILE_LANGUAGE:CXX>:
  -Wconversion
  -Wno-volatile
  -Wold-style-cast
  -Wuseless-cast
  -Wsuggest-override>
  $<$<CONFIG:debug>:-Og -g3 -ggdb>
  $<$<CONFIG:release>:-Og -g0>
  -Wno-psabi
)

target_link_options(${CMAKE_PROJECT_NAME} PRIVATE
  -T${MCU_LINKER_SCRIPT}
  ${CPU_PARAMETERS}
  -Wl,-Map=${CMAKE_PROJECT_NAME}.map
  $<$<VERSION_GREATER:$<C_COMPILER_VERSION>,10.3.1>:-Wl,--no-warn-rwx-segments>
  -u _printf_float
  -Wl,--print-memory-usage
)

###############################################################################
add_custom_command(
  OUTPUT ${CMAKE_PROJECT_NAME}.bin
  DEPENDS ${CMAKE_PROJECT_NAME}
  COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${CMAKE_PROJECT_NAME}> ${CMAKE_PROJECT_NAME}.bin
  COMMENT "Creating binary"
)

add_custom_command(
  OUTPUT ${CMAKE_PROJECT_NAME}.hex
  DEPENDS ${CMAKE_PROJECT_NAME}
  COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${CMAKE_PROJECT_NAME}> ${CMAKE_PROJECT_NAME}.hex
  COMMENT "Creating hex"
)

add_custom_target(
  firmware_images ALL
  DEPENDS ${CMAKE_PROJECT_NAME}.bin ${CMAKE_PROJECT_NAME}.hex
)

option(DUMP_ASM "Create full assembly of final executable" OFF)
if (${DUMP_ASM})
  add_custom_command(
    TARGET ${CMAKE_PROJECT_NAME}
    COMMAND ${CMAKE_OBJDUMP} -D -C $<TARGET_FILE:${CMAKE_PROJECT_NAME}> > ${CMAKE_PROJECT_NAME}.s
    COMMENT "Creating dissasembly of firmware: ${CMAKE_PROJECT_NAME}.s"
  )
endif()

