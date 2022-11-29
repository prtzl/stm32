#! /usr/bin/env bash

Def='\e[0m';
Gre='\e[0;32m';
Red='\e[0;31m';
Blu='\e[0;34m';

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

HELP="./generate.sh <g/a> <destination directory>"

# Check generation type
GENTYPE=$1
if [[ "$GENTYPE" == "" ]]; then
    abort "$HELP"
elif [[ "$GENTYPE" != "g" && "$GENTYPE" != "a" ]]; then
    abort "Select generate type!\n$HELP"
fi

# Check input destination directory validity
INSTALL_DIR=$2
if [[ "$INSTALL_DIR" == "" ]]; then
    abort "$HELP"
elif [[ -d $INSTALL_DIR ]]; then
    if [[ "$GENTYPE" == "g" ]]; then
        abort "Directory $INSTALL_DIR already exists!"
    fi
else
    if [[ "$GENTYPE" == "a" ]]; then
        abort "Directory $INSTALL_DIR does not exists!"
    fi
    BASEDIR=$(dirname $INSTALL_DIR)
    if [[ ! -d $BASEDIR ]]; then
        abort "Base path for $INSTALL_DIR is invalid!"
    fi
    info "Generating directory $INSTALL_DIR"
    mkdir -p $INSTALL_DIR
fi

FORCE=$3
if [[ "$FORCE" != "" ]]; then
    if [[ "$FORCE" != "-f" ]]; then
        abort "Unknown flag: $FORCE"
    else
        FORCE="y"
    fi
fi

# Copy sources
info "Copying sources"
FILES_BUILD="CMakeLists.txt gcc-arm-none-eabi.cmake Makefile .clang-format"
FILES_NIX="flake.nix flake.lock default.nix .envrc"
FILES_CONTAINER="Dockerfile docker-compose.yml .dockerignore"
for f in $FILES_BUILD $FILES_NIX $FILES_CONTAINER; do
    if [[ -f $INSTALL_DIR/$f && "$FORCE" != "y" ]]; then
        abort "File $INSTALL_DIR/$f already exists!"
    fi
    cp $f $INSTALL_DIR
done

# Try replacing defines, library paths and MCU type from .mxproject file
if [ ! -f $INSTALL_DIR/.mxproject ]; then
    info "No .mxproject file found in $INSTALL_DIR, skipping mod"
    exit 0
fi

# Find startup and linker files
STARTUP_FILE=$(find $INSTALL_DIR -name 'startup*' -and -name '*.s')
LINKER_SCRIPT=$(find $INSTALL_DIR -name '*FLASH.ld')

# Find MCU_MODEL from .mxproject
MCU_MODEL_LN=$(grep '^CDefines' $INSTALL_DIR/.mxproject)
IFS=';' read -ra array <<< "$MCU_MODEL_LN"
MCU_MODEL=""
for w in "${array[@]}"; do
    if [[ "$w" == "STM32"* ]]; then
        MCU_MODEL=$(echo $w | tr -d '\r')
        break
    fi
done

# Find MCU_FAMILY from .mxproject
MCU_FAMILY_LN=$(grep '^LibFiles' $INSTALL_DIR/.mxproject)
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

# Find cortex type and choose fpu
CPU_CORE_LN=$(grep '.cpu' $STARTUP_FILE)
IFS=' ' read -ra array <<< "$CPU_CORE_LN"
CPU_CORE=""
for w in "${array[@]}"; do
    if [[ "$w" == "cortex"* ]]; then
        RAW=${w/cortex-m/}
        CPU_CORE=$(echo $RAW | tr -d '\r')
        break
    fi
done
if [[ "$CPU_CORE" == "" ]]; then
    abort "Could not find core type!"
fi

FPU_TYPE=""
FPU_MODE=""
case $CPU_CORE in
    4) FPU_TYPE="fpv4-sp-d16"; FPU_MODE="hard";;
    *) abort "Unsupported FPU type!";;
esac

info "Found project info:"
succ \
"MCU_MODEL: $MCU_MODEL\n"\
"MCU_FAMILY: $MCU_FAMILY\n"\
"CPU: $CPU_CORE, FPU: $FPU_TYPE, $FPU_MODE\n"\
"STARTUP_FILE: $STARTUP_FILE\n"\
"LINKER_SCRIPT: $LINKER_SCRIPT"

# Find and replace definitions in CMakeLists.txt
function replace()
{
    file=$1
    find=$2
    replace=$3
    sed -i "s/$find/$replace/g" $file
}

replace $INSTALL_DIR/CMakeLists.txt "set(MCU_FAMILY.*" "set(MCU_FAMILY $MCU_FAMILY)"
replace $INSTALL_DIR/CMakeLists.txt "set(MCU_MODEL.*" "set(MCU_MODEL $MCU_MODEL)"
out="${STARTUP_FILE/${INSTALL_DIR}\//}"
out="${out/\//\\/}"
replace $INSTALL_DIR/CMakeLists.txt "set(STARTUP_SCRIPT.*" "set(STARTUP_SCRIPT \${CMAKE_CURRENT_SOURCE_DIR}\/$out)"
out="${LINKER_SCRIPT/${INSTALL_DIR}\//}"
out="${out/\//\\/}"
replace $INSTALL_DIR/CMakeLists.txt "set(MCU_LINKER_SCRIPT.*" "set(MCU_LINKER_SCRIPT \${CMAKE_CURRENT_SOURCE_DIR}\/$out)"
replace $INSTALL_DIR/CMakeLists.txt "-mcpu=cortex-m.*" "-mcpu=cortex-m$CPU_CORE"
replace $INSTALL_DIR/CMakeLists.txt "-mfpu=.*" "-mfpu=$FPU_TYPE"
replace $INSTALL_DIR/CMakeLists.txt "-mfloat-abi=.*" "-mfloat-abi=$FPU_MODE)"

info "Finished!"
