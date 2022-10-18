{ stdenv
, cmake
, gnumake
, gcc-arm-embedded
, clang-tools
}:

stdenv.mkDerivation rec {
  name = "firmware";
  src = ./.;

    nativeBuildInputs = [ cmake gnumake gcc-arm-embedded ];

  dontPatch = true;
  dontFixup = true;
  dontStrip = true;
  dontPatchELF = true;

  CMAKE_BUILD_SYSTEM = "Unix Makefiles";
  CMAKE_BUILD_TYPE = "Debug";

  device = "STM32F407VG";

  cmakeFlags = [
    "-DPROJECT_NAME=${name}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_TOOLCHAIN_FILE=gcc-arm-none-eabi.cmake"
    #"-DDUMP_ASM=ON"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp *.bin *.elf *.s $out/bin
    cp compile_commands.json $out
  '';
}
