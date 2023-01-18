{ stdenvNoCC
, cmake
, gnumake
, gcc-arm-embedded
, clang-tools
}:

stdenvNoCC.mkDerivation rec {
  pname = "firmware";
  version = "0.0.1";
  src = ./.;

  nativeBuildInputs = [ cmake gnumake gcc-arm-embedded ];

  dontPatch = true;
  dontFixup = true;
  dontStrip = true;
  dontPatchELF = true;

  device = "STM32F407VG";

  cmakeFlags = [
    "-GUnix Makefiles"
    "-DPROJECT_NAME=${pname}"
    "-DCMAKE_BUILD_TYPE=Debug"
    "-DDUMP_ASM=OFF"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp *.bin *.elf *.s $out/bin
    cp compile_commands.json $out
  '';
}
