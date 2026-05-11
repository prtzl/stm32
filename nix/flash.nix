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
    let
      isJlink = variant == "jlink";
      isStlink = variant == "stlink";

      expectedExt =
        if isJlink then
          "elf"
        else if isStlink then
          "bin"
        else
          throw "Unsupported flasher variant: ${variant}";
    in
    pkgs.writeShellApplication {
      name = "flash-${variant}";

      runtimeInputs = lib.optionals isJlink [ jlink ] ++ lib.optionals isStlink [ pkgs.stlink ];

      text = ''
        executable="''${1:-}"
        flasher="${variant}"

        usage() {
          echo "Usage: $(basename "$0") <firmware.${expectedExt}>"
          exit 1
        }

        if [ -z "$executable" ]; then
          usage
        fi

        if [ ! -f "$executable" ]; then
          echo "File not found: $executable"
          exit 1
        fi

        ext="''${executable##*.}"

        if [ "$ext" != "${expectedExt}" ]; then
          echo "Invalid firmware type for ${variant}:"
          echo "  expected: .${expectedExt}"
          echo "  got:      .$ext"
          exit 1
        fi

        if [[ "$flasher" == "jlink" ]]; then
          tmp=$(mktemp)

          cleanup() {
            rm -f "$tmp"
          }

          trap cleanup EXIT

          cp "${jlinkScriptTeplate}" "$tmp"
          sed -i "s@%ELF%@$executable@" "$tmp"

          exec JLinkExe -commanderscript "$tmp" -NoGui 1
        else
          exec st-flash --reset write "$executable" 0x08000000
        fi
      '';
    };
in
{
  flash-jlink = mkFlasher "jlink";
  flash-stlink = mkFlasher "stlink";
}
