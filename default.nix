{ stdenv
, cmake
, gnumake
, gcc-arm-embedded
, clang-tools
}:

stdenv.mkDerivation rec {
  pname = "firmware";
  version = "0.0.1";
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
    "-DPROJECT_NAME=${pname}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
    #"-DDUMP_ASM=ON"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp *.bin *.elf *.s $out/bin
    cp compile_commands.json $out
  '';
}
