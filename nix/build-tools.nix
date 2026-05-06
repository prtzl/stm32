{
  firmware,
  pkgs,
  ...
}:

let
  shellExports = ''
    string=${(builtins.concatStringsSep "/bin:" firmware.debug.buildInputs) + "/bin"}
    export PATH=''${string}:$PATH
    build_dir=''${1:-build}
  '';
in
{
  meson = pkgs.writeShellScriptBin "meson" ''
    ${shellExports}
    cat meson_options.txt
    meson setup --cross-file=./gcc-arm-none-eabi.meson --cross-file=./stm32f4.meson -Dproject_name="${(firmware.debug).pname}" -Dbuildtype="${(firmware.debug).buildtype}" "$build_dir"
  '';

  cmake = pkgs.writeShellScriptBin "cmake" ''
    ${shellExports}
    cmake -B$build_dir -DPROJECT_NAME="${(firmware.debug).pname}" -DPROJECT_VERSION="${(firmware.debug).version}" -DCMAKE_BUILD_TYPE="${(firmware.debug).buildtype}"
  '';
}
