{
  jlink,
  jlinkSpeedKhz,
  lib,
  pkgs,
  ...
}:

let
  jlinkScriptTeplate = pkgs.writeText "jscript" ''
    ExitOnError 1
    device STM32F407VG
    si SWD
    speed ${jlinkSpeedKhz}
    loadfile %ELF%
    r
    g
    qc
  '';

  mkFlasher =
    variant:
    assert variant == "jlink" || variant == "stlink";
    pkgs.writeShellApplication {
      name = "flash-${variant}";
      runtimeInputs =
        lib.optional (variant == "jlink") jlink ++ lib.optional (variant == "stlink") pkgs.stlink;
      text = ''
        elf="''${1:-}"
        if [ -z "$elf" ]; then
          echo "Usage: $(basename "$0") <firmware.elf>"
          exit 1
        fi

        if [ ! -f "$elf" ]; then
          echo "File not found: $elf"
          exit 1
        fi

        flasher="${variant}"
        if [[ "$flasher" == "jlink" ]]; then
          tmp=$(mktemp)
          cleanup() { rm -f "$tmp"; }
          trap cleanup EXIT

          cp "${jlinkScriptTeplate}" "$tmp"
          sed -i "s@%ELF%@''${elf}@" "$tmp"

          exec JLinkExe -commanderscript "$tmp" -NoGui 1
        elif [[ "$flasher" == "stlink" ]]; then
          exec st-flash --reset write "$elf" 0x08000000
        fi
      '';
    };
in
{
  flash-jlink = mkFlasher "jlink";
  flash-stlink = mkFlasher "stlink";
}
