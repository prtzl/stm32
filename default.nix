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

    dontUseCmakeConfigure = true;
    dontPatch = true;
    dontFixup = true;
    dontStrip = true;
    dontPatchELF = true;

    CMAKE_BUILD_SYSTEM = "Unix Makefiles";
    CMAKE_BUILD_DIR = "build";
    CMAKE_BUILD_TYPE = "Debug";

    device = "STM32F407VG";

    buildPhase = ''
        cmake \
            -G "${CMAKE_BUILD_SYSTEM}" \
            -B${CMAKE_BUILD_DIR} \
            -DPROJECT_NAME=${name} \
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
            -DCMAKE_TOOLCHAIN_FILE=gcc-arm-none-eabi.cmake \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
            -DDUMP_ASM=ON
        cmake --build ${CMAKE_BUILD_DIR} -j
    '';

    installPhase = ''
        mkdir -p $out/bin
        cp ${CMAKE_BUILD_DIR}/*.bin ${CMAKE_BUILD_DIR}/*.elf ${CMAKE_BUILD_DIR}/*.s $out/bin
        cp ${CMAKE_BUILD_DIR}/compile_commands.json $out
    '';
}
