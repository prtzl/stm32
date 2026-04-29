.PHONY: all build build-container cmake format format-linux flash-stlink flash-jlink format-container shell image build-container clean clean-image clean-all
############################### Native Makefile ###############################

BUILD_DIR ?= build
PROJECT_NAME ?= firmware
BUILD_TYPE ?= debug
VERSION := $(shell cat ./VERSION)
FIRMWARE := $(BUILD_DIR)/$(PROJECT_NAME)-$(BUILD_TYPE)-$(VERSION).elf
FIRMWARE_BIN := $(BUILD_DIR)/$(PROJECT_NAME)-$(BUILD_TYPE)-$(VERSION).bin
PLATFORM := $(if $(OS),$(OS),$(shell uname -s))
FIRMWARE_FLASH_ADDRESS = $(shell arm-none-eabi-readelf -l $(FIRMWARE) | awk '/LOAD/ { print $$3; exit }')
JLINK_SCRIPT := $(BUILD_DIR)/jlink-script

# Device specific!
DEVICE ?= STM32F407VG

ifeq ($(PLATFORM),Windows_NT)
    BUILD_SYSTEM ?= MinGW Makefiles
else
    ifeq ($(PLATFORM),Linux)
        BUILD_SYSTEM ?= Unix Makefiles
    else
        @echo "Unsuported platform"
        exit 1
    endif
endif

all: build

build: cmake
	@MAKEFLAGS+=--no-print-directory; cmake --build $(BUILD_DIR)

cmake: $(BUILD_DIR)/Makefile

$(BUILD_DIR)/Makefile: CMakeLists.txt
	@cmake \
		-G "$(BUILD_SYSTEM)" \
		-B$(BUILD_DIR) \
		-DPROJECT_NAME=$(PROJECT_NAME) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DDUMP_ASM=OFF

# Formats all user modified source files (add ones that are missing)
SRCS := $(shell find Project -name '*.[ch]' -or -name '*.[ch]pp') Core/Src/main.c
format: $(addsuffix .format,$(SRCS))
%.format: %
	clang-format -i $<

# Formats all CubeMX generated sources to unix style - removes \r from line endings
# Add any new directories, like Middlewares and hidden files
HIDDEN_FILES := .mxproject .project .cproject
FOUND_HIDDEN_FILES := $(shell for f in $(HIDDEN_FILES);do if [[ -e $$f ]]; then echo $$f;fi; done)
FORMAT_LINUX := $(shell find Core Drivers -name '*' -type f; find . -name '*.ioc') $(FOUND_HIDDEN_FILES)

format-linux: $(addsuffix .format-linux,$(FORMAT_LINUX))
%.format-linux: %
	$(if $(filter $(PLATFORM),Linux),dos2unix -q $<,)

flash-st: build
	@echo "Flashing the board with ST-LINK"
	@st-flash --reset write $(FIRMWARE_BIN) $(FIRMWARE_FLASH_ADDRESS) > stlink.log 2>&1 || cat stlink.log
	@echo "Flashing complete!"

$(JLINK_SCRIPT):
	@touch $@
	@echo ExitOnError 1 > $@
	@echo device $(DEVICE) >> $@
	@echo si 1 >> $@
	@echo speed 10000 >> $@
	@echo loadfile $(FIRMWARE) >> $@
	@echo -e "r\ng\nqc" >> $@

flash-jlink: build | $(JLINK_SCRIPT)
	@echo "Flashing the board with JLINK"
	@JLinkExe -commanderScript $(BUILD_DIR)/jlink-script > jlink.log 2> >(tee -a jlink.log >&2) || cat jlink.log
	@echo "Flashing complete!"

clean:
	rm -rf $(BUILD_DIR) jlink.log stlink.log

################################## Container ##################################

UID ?= $(shell id -u)
GID ?= $(shell id -g)
USER ?= $(shell id -un)
GROUP ?= $(if $(filter $(PLATFORM), Windows_NT),$(shell id -un),$(shell id -gn))

ifeq ($(PLATFORM),Windows_NT)
    WIN_PREFIX = winpty
    WORKDIR_PATH = "//workdir"
    WORKDIR_VOLUME = "/$$(pwd -W):/workdir"
else
    WORKDIR_PATH = /workdir
    WORKDIR_VOLUME = "$$(pwd):/workdir"
endif

CONTAINER_TOOL ?= docker
CONTAINER_FILE := Dockerfile
IMAGE_NAME := fedora-arm-embedded-dev
CONTAINER_NAME := fedora-arm-embedded-dev

NEED_IMAGE = $(shell $(CONTAINER_TOOL) image inspect $(IMAGE_NAME) 2> /dev/null > /dev/null || echo image)
# usefull if you have a always running container in the background: NEED_CONTAINER = $(shell $(CONTAINER_TOOL) container inspect $(CONTAINER_NAME) 2> /dev/null > /dev/null || echo container)
PODMAN_ARG = $(if $(filter $(CONTAINER_TOOL), podman),--userns=keep-id,)
CONTAINER_RUN = $(WIN_PREFIX) $(CONTAINER_TOOL) run \
				--name $(CONTAINER_NAME) \
				--rm \
				-it \
				$(PODMAN_ARG) \
				-v $(WORKDIR_VOLUME) \
				-w $(WORKDIR_PATH) \
				--security-opt label=disable \
				--hostname $(CONTAINER_NAME) \
				$(IMAGE_NAME)

build-container: $(NEED_IMAGE)
	$(CONTAINER_RUN) bash -lc 'make -j$(shell nproc)'

format-container:
	$(CONTAINER_RUN) bash -lc 'make format -j$(shell nproc)'

format-linux-container:
	$(CONTAINER_RUN) bash -lc 'make format-linux'

shell:
	$(CONTAINER_RUN) bash -l

image: $(CONTAINER_FILE)
	$(CONTAINER_TOOL) build \
		-t $(IMAGE_NAME) \
		-f=$(CONTAINER_FILE) \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg USERNAME=$(USER) \
		--build-arg GROUPNAME=$(GROUP) \
		.

clean-image:
	$(CONTAINER_TOOL) container rm -f $(CONTAINER_NAME) 2> /dev/null > /dev/null || true
	$(CONTAINER_TOOL) image rmi -f $(IMAGE_NAME) 2> /dev/null > /dev/null || true

clean-all: clean clean-image
