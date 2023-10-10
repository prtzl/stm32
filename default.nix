{ stdenv
, cmake
, gnumake
, gcc-arm-embedded
, clang-tools
, meson
, ninja
, bash
, buildtype ? "Debug"
, lib
}:

assert buildtype == "Debug" || buildtype == "Release";

stdenv.mkDerivation rec {
  pname = "firmware";
  version = lib.fileContents ./VERSION;
  src = ./.;

  # order of ninja+meson nad cmake+gnumake will impact which generator is chosen
  buildInputs = [ gcc-arm-embedded ninja meson cmake gnumake ];

  dontFixup = true; # if you use fixupPhase (do something after build), remove this
  dontStrip = true;
  dontPatchELF = true;

  # Firmware/device info
  device = "STM32F407VG";
  binary = "${pname}-${version}.bin";

  # cmake
  cmakeFlags = [
    "-DPROJECT_NAME=${pname}"
    "-DCMAKE_BUILD_TYPE=${buildtype}"
    "-DDUMP_ASM=OFF"
  ];

  # meson
  mesonBuildType = "${lib.strings.toLower buildtype}";
  mesonFlags = [
    "--cross-file=gcc-arm-none-eabi.meson"
    "--cross-file=stm32f4.meson"
  ];

  patchPhase = ''
    substituteInPlace glob.sh \
      --replace '/usr/bin/env bash' ${bash}/bin/bash
  '';

  # "save" outputs
  installPhase = ''
    mkdir -p $out/bin
    cp *.bin *.elf *.s $out/bin
    cp compile_commands.json $out
  '';
}
