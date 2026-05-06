{
  jlink,
  jlinkSpeedKhz,
  pkgs,
  ...
}:

let
  mkFirmware = buildtype: pkgs.callPackage ./firmware.nix { inherit buildtype; };
  firmware = {
    debug = mkFirmware "debug";
    release = mkFirmware "release";
  };

  flash = import ./flash.nix {
    inherit pkgs jlink jlinkSpeedKhz;
  };

  debug = import ./debug.nix {
    inherit pkgs jlink jlinkSpeedKhz;
  };

  buildTools = import ./build-tools.nix {
    inherit pkgs firmware;
  };

  mkProject =
    fw: mkFlash:
    pkgs.symlinkJoin {
      name = "project-output";
      paths = [
        fw
        (mkFlash fw)
      ];
      meta.mainProgram = (mkFlash fw).name;
    };
in
{
  inherit
    firmware
    flash
    debug
    buildTools
    mkProject
    ;
}
