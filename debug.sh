#!/usr/bin/env bash

exe=$1 
if [ -n "$exe" ]; then
    echo "Provide executable path to .elf"
    exit 1
fi

JLinkGDBServerCLExe \
  -device STM32F407VG \
  -if SWD \
  -speed 4000 \
  -port 2331 > jlink.log 2>&1 &

JLINK_PID=$!

# Kill J-Link server when script exits
trap 'kill $JLINK_PID' EXIT

# Give the server a moment to start
sleep 1

# Start GDB interactively and run commands
arm-none-eabi-gdb $exe \
  -ex "layout next" \
  -ex "layout next" \
  -ex "target remote localhost:2331" \
  -ex "load" \
  -ex "break main" \
  -ex "continue"
