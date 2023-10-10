{ stdenv
, cmake
, gnumake
, gcc-arm-embedded
, clang-tools
, meson
, ninja
, bash
, buildType ? "debug"
, lib
}:

assert buildType == "debug" || buildType == "release";

stdenv.mkDerivation rec {
  pname = "firmware";
  version = lib.fileContents ./VERSION;
  src = ./.;

  buildInputs = [ ninja meson gcc-arm-embedded ];

  dontFixup = true;
  dontStrip = true;
  dontPatchELF = true;

  device = "STM32F407VG";

  cmakeFlags = [
    "-DPROJECT_NAME=${pname}"
    "-DCMAKE_BUILD_TYPE=Debug"
    "-DDUMP_ASM=OFF"
  ];

  buildtype = buildType;
  mesonBuildType = "${buildtype}";
  mesonFlags = [
    "--cross-file=gcc-arm-none-eabi.meson"
    "--cross-file=stm32f4.meson"
  ];

  binary = "${pname}-${version}.bin";

  patchPhase = ''
    substituteInPlace glob.sh \
      --replace '/usr/bin/env bash' ${bash}/bin/bash
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp *.bin *.elf *.s $out/bin
    cp compile_commands.json $out
  '';
}
