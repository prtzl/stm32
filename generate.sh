#! /usr/bin/env bash

Def='\e[0m';
Gre='\e[0;32m';
Red='\e[0;31m';
Blu='\e[0;34m';
Ora='\e[0;33m';

function print()
{
    echo -e "$@${Def}"
}

function error()
{
    print $Red"$@"
}

function info()
{
    print $Blu"$@"
}

function warn()
{
    print $Ora"$@"
}

function succ()
{
    print $Gre"$@"
}

function abort()
{
    print $Red"ERROR: $@"$Def
    exit 1
}

function check()
{
    if ! eval "$@"; then
        abort "Command: $@ failed!"
    fi
}

################################################################################

# AUTO_GIT="y"
HELP="./generate.sh <g/a> <destination directory>"

# Check input destination directory validity
INSTALL_DIR=$1
if [[ "$INSTALL_DIR" == "" ]]; then
    abort "$HELP"
elif [[ ! -d $INSTALL_DIR ]]; then
    abort "Directory $INSTALL_DIR does not exists!"
fi

# Overwrite existing files
FORCE=$2
if [[ "$FORCE" != "" ]]; then
    if [[ "$FORCE" != "-f" ]]; then
        abort "Unknown flag: $FORCE"
    else
        FORCE="y"
    fi
fi

# Greet
succ "STM32 project template bringup @ $INSTALL_DIR $(if [[ "$FORCE" == "y" ]]; then echo -n 'with FORCE'; fi)"

if [[ "$AUTO_GIT" == "y" ]]; then
    pushd $INSTALL_DIR
    git reset --hard
    git clean -fdx
    popd
fi

# Copy sources
info "Copying sources to $INSTALL_DIR"
FILES_BUILD="CMakeLists.txt gcc-arm-none-eabi.cmake Makefile .clang-format"
FILES_NIX="flake.nix flake.lock default.nix .envrc"
FILES_CONTAINER="Dockerfile docker-compose.yml .dockerignore"
for f in $FILES_BUILD $FILES_NIX $FILES_CONTAINER; do
    if [[ -f $INSTALL_DIR/$f && "$FORCE" != "y" ]]; then
        warn "\tFile $INSTALL_DIR/$f already exists!"
        continue
    fi
    print "\tCopying: $f"
    cp $f $INSTALL_DIR
done

# Try replacing defines, library paths and MCU type from .mxproject file
mxproject=$(find $INSTALL_DIR -name '.mxproject')
if [ ! -f $mxproject ]; then
    info "No .mxproject file found in $INSTALL_DIR, skipping further modification of config sources!"
    exit 0
fi

# Find startup and linker files - will only take first found path
pushd $INSTALL_DIR > /dev/null
STARTUP_SCRIPT_RELPATH=$(find -name 'startup*' -and -name '*.s' | head -n1 | sed 's/^\.\///')
STARTUP_SCRIPT_PATH="$INSTALL_DIR/$STARTUP_SCRIPT_RELPATH"
LINKER_SCRIPT_RELPATH=$(find -name '*FLASH.ld' | head -n1 | sed 's/^\.\///')
LINKER_SCRIPT_PATH="$INSTALL_DIR/$LINKER_SCRIPT_RELPATH"
popd > /dev/null
if [[ ! -f "$STARTUP_SCRIPT_PATH" || ! -f "$LINKER_SCRIPT_PATH" ]]; then
    abort "Startup and/or linker files not found in $INSTALL_DIR!"
fi

# Get the MCU model from .mxproject file. Example line:
# CDefines=USE_HAL_DRIVER;STM32F303x8;USE_HAL_DRIVER;USE_HAL_DRIVER;
MCU_MODEL_LN=$(grep '^CDefines' $mxproject)
IFS=';' read -ra array <<< "$MCU_MODEL_LN"
MCU_MODEL=""
for w in "${array[@]}"; do
    if [[ "$w" == "STM32"* ]]; then
        MCU_MODEL=$(echo $w | tr -d '\r')
        break
    fi
done
if [[ "$MCU_MODEL" == "" ]]; then
    abort "MCU model name not found in $mxproject"
fi

# Get the MCU family from driver paths in .mxproject file. Example line:
# LibFiles=Drivers/STM32F4xx_HAL_Driver/Inc/stm32f4xx_hal_tim.h; ...
MCU_FAMILY_LN=$(grep '^LibFiles' $mxproject | sed 's/\n//g')
IFS='/' read -ra array <<< "$MCU_FAMILY_LN"
MCU_FAMILY=""
for w in "${array[@]}"; do
    IFS='_' read -ra array2 <<< "$w"
    for w2 in "${array2[@]}"; do
        if [[ "$w2" == "STM32"* ]]; then
            MCU_FAMILY=$(echo $w2 | tr -d '\r')
            break 2
        fi
    done
done
if [[ "$MCU_FAMILY" == "" ]]; then
    abort "MCU family name not found in $mxproject"
fi

# Find cortex type and choose fpu
CPU_CORE_LN=$(grep '.cpu' $STARTUP_SCRIPT_PATH)
IFS=' ' read -ra array <<< "$CPU_CORE_LN"
CPU_CORE=""
for w in "${array[@]}"; do
    if [[ "$w" == "cortex"* ]]; then
        RAW=${w/cortex-/}
        CPU_CORE=$(echo $RAW | tr -d '\r')
        break
    fi
done
if [[ "$CPU_CORE" == "" ]]; then
    abort "Could not find core type from $STARTUP_SCRIPT_PATH!"
fi

FPU_TYPE=""
FPU_MODE=""
case $CPU_CORE in
    m4) FPU_TYPE="fpv4-sp-d16"; FPU_MODE="hard";;
    m7) FPU_TYPE="fpv5-sp-d16"; FPU_MODE="hard";;
    *) info "No FPU for this CPU core!";;
esac

info "Found project info:"
print "\tMCU_MODEL: $MCU_MODEL"
print "\tMCU_FAMILY: $MCU_FAMILY"
print "\tCPU: $CPU_CORE, FPU: $FPU_TYPE, FPU_MODE: $FPU_MODE"
if [[ "\t$CPU_CORE" == "m7" ]]; then warn "M7: check if CPU supports double precission float (remove -sp from -mfpu)"; fi
print "\tSTARTUP_SCRIPT: $STARTUP_SCRIPT_RELPATH"
print "\tLINKER_SCRIPT: $LINKER_SCRIPT_RELPATH"

if [[ "$AUTO_GIT" == "y" ]]; then
    pushd $INSTALL_DIR
    git add .
    popd
fi

# Find and replace expression in files
function replace()
{
    file=$1
    find=$2
    replace=$3
    sed -i "s@$find@$replace@g" -- $file
}

# If expression is not found, it is removed
function remove()
{
    file=$1
    find=$2
    sed -i "/$find/d" -- $file
}

function append()
{
    file=$1
    find=$2
    append=$3
    sed -i "s@$find@&$append@" -- $file
}

# Find and replace cmake set configurations (single line only ...)
function replace_cmake_set()
{
    file=$1
    option=$2
    replace=$3
    replace $1 "^set($option.*" "set($option $replace)"
}

# Modify MCU definitions
replace_cmake_set $INSTALL_DIR/CMakeLists.txt "MCU_MODEL" "$MCU_MODEL" 
replace_cmake_set $INSTALL_DIR/CMakeLists.txt "MCU_FAMILY" "$MCU_FAMILY" 
replace_cmake_set $INSTALL_DIR/CMakeLists.txt "STARTUP_SCRIPT" "\${CMAKE_CURRENT_SOURCE_DIR}/$STARTUP_SCRIPT_RELPATH" 
replace_cmake_set $INSTALL_DIR/CMakeLists.txt "MCU_LINKER_SCRIPT" "\${CMAKE_CURRENT_SOURCE_DIR}/$LINKER_SCRIPT_RELPATH" 

# Modify/remove/add CPU definitions
replace $INSTALL_DIR/CMakeLists.txt "-mcpu.*" "-mcpu=cortex-$CPU_CORE"
if [[ "$FPU_TYPE" == "" ]]; then
    remove $INSTALL_DIR/CMakeLists.txt "-mfpu.*"
    remove $INSTALL_DIR/CMakeLists.txt "-mfloat-abi.*"
    append $INSTALL_DIR/CMakeLists.txt "-mcpu.*" ")"
else
    replace $INSTALL_DIR/CMakeLists.txt "-mfpu=.*" "-mfpu=$FPU_TYPE"
    replace $INSTALL_DIR/CMakeLists.txt "-mfloat-abi=.*" "-mfloat-abi=$FPU_MODE)"
fi

succ "Finished!"
