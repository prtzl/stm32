{ stdenv
, cmake
, gnumake
, gcc-arm-embedded
, clang-tools
, meson
, ninja
, bash
, buildType ? "debug"
}:

assert buildType == "debug" || buildType == "release";

stdenv.mkDerivation rec {
  pname = "firmware";
  version = "0.0.1";
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

  mesonBuildType = "${buildType}";
  mesonFlags = [
    "--cross-file=gcc-arm-none-eabi.meson"
    "--cross-file=stm32f4.meson"
  ];

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
