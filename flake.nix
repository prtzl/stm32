{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    jlink-pack.url = "github:prtzl/jlink-nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        stdenv = pkgs.stdenv;
        jlink = inputs.jlink-pack.defaultPackage.${system}.overrideAttrs
          (attrs: { meta.license = ""; });

        shellExports = ''
          string=${
            (builtins.concatStringsSep "/bin:" firmware.debug.buildInputs)
            + "/bin"
          }
          export PATH=''${string}:$PATH
          buildir=''${1:-build}
        '';

        meson = pkgs.writeShellScriptBin "meson" ''
          ${shellExports}
          cat meson_options.txt
          meson setup --cross-file=./gcc-arm-none-eabi.meson --cross-file=./stm32f4.meson -Dproject_name="${
            (firmware.debug).pname
          }" -Dbuildtype="${(firmware.debug).buildtype}" "$buildir"
        '';

        cmake = pkgs.writeShellScriptBin "cmake" ''
          ${shellExports}
          cmake -B$buildir -DPROJECT_NAME="${
            (firmware.debug).pname
          }" -DPROJECT_VERSION="${
            (firmware.debug).version
          }" -DCMAKE_BUILD_TYPE="${(firmware.debug).buildtype}"
        '';

        mkFirmware = { buildtype }:
          pkgs.callPackage ./default.nix { inherit buildtype; };
        firmware.debug = mkFirmware { buildtype = "debug"; };
        firmware.release = mkFirmware { buildtype = "release"; };

        mkFlashStlink = fw:
          pkgs.writeShellApplication {
            name = "flash-stlink-${fw.buildtype}";
            text =
              "st-flash --reset write ${fw}/bin/${fw.binary}.bin 0x08000000";
            runtimeInputs = [ pkgs.stlink ];
          };

        jlink-script = fw:
          pkgs.writeTextFile {
            name = "jlink-script-${fw.buildtype}";
            text = ''
              device ${fw.device}
              si 1
              speed 4000
              loadfile ${fw}/bin/${fw.binary},0x08000000
              r
              g
              qc
            '';
          };

        mkFlashJlink = fw:
          pkgs.writeShellApplication {
            name = "flash-jlink-${fw.buildtype}";
            text = "JLinkExe -commanderscript ${jlink-script fw}";
            runtimeInputs = [ jlink ];
          };

        mkProject = fw: mkFlash:
          pkgs.symlinkJoin {
            name = "project-output";
            paths = [ fw (mkFlash fw) ];
            meta.mainProgram = "${(mkFlash fw).name}";
          };

        debug-jlink = pkgs.writeShellScriptBin "debug" ''
          ${shellExports}
          exe=${firmware.debug}/bin/${firmware.debug.executable}
          if [ -z "$exe" ]; then
              echo "Provide executable path to .elf"
              exit 1
          fi

          JLinkGDBServerCLExe \
            -device STM32F407VG \
            -if SWD \
            -speed 4000 \
            -port 2331 > jlink.log 2>&1 &

          JLINK_PID=$!

          # Kill J-Link server when script exits
          trap 'kill $JLINK_PID' EXIT

          # Give the server a moment to start
          sleep 1

          # Start GDB interactively and run commands
          arm-none-eabi-gdb $exe \
            -ex "layout next" \
            -ex "layout next" \
            -ex "target remote localhost:2331" \
            -ex "load" \
            -ex "break main" \
            -ex "continue"
        '';
      in {
        packages = rec {
          inherit meson cmake;
          default = debug;
          debug = mkProject firmware.debug mkFlashJlink;
          release = mkProject firmware.release mkFlashJlink;
          debugst = mkProject firmware.debug mkFlashStlink;
          releasest = mkProject firmware.release mkFlashStlink;
          debugger = pkgs.symlinkJoin {
            name = "debug";
            paths = [ debug-jlink firmware.debug ];
            meta.mainProgram = "${debug-jlink.name}";
          };
        };

        devShell = pkgs.mkShellNoCC {
          nativeBuildInputs = (firmware.debug.buildInputs or [ ]) ++ [
            pkgs.clang-tools
            jlink
            pkgs.stlink
            pkgs.dos2unix
            pkgs.glibc_multi
            pkgs.clang
          ];
        };
      });
}
