{
  jlink,
  jlinkSpeedKhz,
  pkgs,
  ...
}:

let
  flashStlink = pkgs.writeShellApplication {
    name = "flash-stlink";
    runtimeInputs = [ pkgs.stlink ];
    text = ''
      set -euo pipefail

      elf="''${1:-}"
      if [ -z "$elf" ]; then
        echo "Usage: flash-stlink <firmware.elf>"
        exit 1
      fi

      if [ ! -f "$elf" ]; then
        echo "File not found: $elf"
        exit 1
      fi

      st-flash --reset write "$elf" 0x08000000
    '';
  };

  flashJlink = pkgs.writeShellApplication {
    name = "flash-jlink";
    runtimeInputs = [ jlink ];
    text = ''
      elf="''${1:-}"
      if [ -z "$elf" ]; then
        echo "Usage: flash-jlink <firmware.elf>"
        exit 1
      fi

      if [ ! -f "$elf" ]; then
        echo "File not found: $elf"
        exit 1
      fi

      tmp=$(mktemp)
      cat > "$tmp" <<EOF
      ExitOnError 1
      device STM32F407VG
      si SWD
      speed ${jlinkSpeedKhz}
      loadfile $elf
      r
      g
      qc
      EOF

      JLinkExe -commanderscript "$tmp"
      rm -f "$tmp"
    '';
  };
in
{
  inherit
    flashStlink
    flashJlink
    ;
}
