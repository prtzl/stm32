{
  jlink,
  jlinkSpeedKhz,
  pkgs,
  ...
}:

let
  mkFlashStlink =
    fw:
    pkgs.writeShellApplication {
      name = "flash-stlink-${fw.buildtype}";
      text = ''
        st-flash --reset write ${fw}/bin/${fw.binary} 0x08000000
      '';
      runtimeInputs = [ pkgs.stlink ];
    };

  jlinkScript =
    fw:
    pkgs.writeTextFile {
      name = "jlink-script-${fw.buildtype}";
      text = ''
        ExitOnError 1
        device ${fw.device}
        si 1
        speed ${jlinkSpeedKhz}
        loadfile ${fw}/bin/${fw.binary},0x08000000
        r
        g
        qc
      '';
    };

  mkFlashJlink =
    fw:
    pkgs.writeShellApplication {
      name = "flash-jlink-${fw.buildtype}";
      text = ''
        JLinkExe -commanderscript ${jlinkScript fw}
      '';
      runtimeInputs = [ jlink ];
    };
in
{
  inherit mkFlashStlink mkFlashJlink;
}
