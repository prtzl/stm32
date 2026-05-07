{
  jlink,
  lib,
  pkgs,
  ...
}:

let
  jlinkSpeedKhz = "10000";

  mkFirmware = buildtype: pkgs.callPackage ./firmware.nix { inherit buildtype; };
  firmware = {
    debug = mkFirmware "debug";
    release = mkFirmware "release";
  };

  flash = import ./flash.nix {
    inherit
      jlink
      jlinkSpeedKhz
      lib
      pkgs
      ;
  };

  debug = import ./debug.nix {
    inherit
      jlink
      jlinkSpeedKhz
      lib
      pkgs
      ;
  };

  buildTools = import ./build-tools.nix {
    inherit pkgs firmware;
  };
in
{
  inherit
    firmware
    flash
    debug
    buildTools
    ;
}
