#!/usr/bin/env bash

exe="${1:-}"
if [ -z "$exe" ]; then
    echo "Usage: $0 <path-to-elf> <jlink/stlink>"
    exit 1
fi

if [ ! -f "$exe" ]; then
    echo "ELF not found: $exe"
    exit 1
fi

debugger="${2:-}"
if [ -z "$exe" ]; then
    echo "Usage: $0 <path-to-elf> <jlink/stlink>"
    exit 1
fi

if [[ "$debugger" == "jlink" ]]; then
    port=2331
    setsid JLinkGDBServerCLExe \
        -device STM32F407VG \
        -if SWD \
        -speed ${jlinkSpeedKhz} \
        -s \
        -port "$port" \
        > jlink.log 2>&1 &
elif [[ "$debugger" == "stlink" ]]; then
    port=4242
    setsid st-util -p "$port" > stlink.log 2>&1 &
else
    echo "Select a valid debugger: jlink/stlink"
    echo "Usage: $0 <path-to-elf> <jlink/stlink>"
    exit 1
fi

JLINK_PID=$!

# Kill J-Link server when script exits
trap 'kill $JLINK_PID' EXIT

# Give the server a moment to start
sleep 1

# Start GDB interactively and run commands
exec arm-none-eabi-gdb $exe \
    -ex "set confirm off" \
    -ex "set pagination off" \
    -ex "layout src" \
    -ex "focus cmd" \
    -ex "target remote localhost:$port" \
    -ex "monitor reset halt" \
    -ex "load" \
    -ex "break main" \
    -ex "continue"
