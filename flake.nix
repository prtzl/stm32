{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    jlink-nix.url = "github:prtzl/jlink-nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      jlink-nix,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, system, ... }:
        let
          jlink = inputs.jlink-nix.packages.${system}.default;

          jlinkSpeedKhz = "10000";

          shellExports = ''
            string=${(builtins.concatStringsSep "/bin:" firmware.debug.buildInputs) + "/bin"}
            export PATH=''${string}:$PATH
            build_dir=''${1:-build}
          '';

          meson = pkgs.writeShellScriptBin "meson" ''
            ${shellExports}
            cat meson_options.txt
            meson setup --cross-file=./gcc-arm-none-eabi.meson --cross-file=./stm32f4.meson -Dproject_name="${(firmware.debug).pname}" -Dbuildtype="${(firmware.debug).buildtype}" "$build_dir"
          '';

          cmake = pkgs.writeShellScriptBin "cmake" ''
            ${shellExports}
            cmake -B$build_dir -DPROJECT_NAME="${(firmware.debug).pname}" -DPROJECT_VERSION="${(firmware.debug).version}" -DCMAKE_BUILD_TYPE="${(firmware.debug).buildtype}"
          '';

          mkFirmware = buildtype: pkgs.callPackage ./default.nix { inherit buildtype; };
          firmware = {
            debug = mkFirmware "debug";
            release = mkFirmware "release";
          };

          mkFlashStlink =
            fw:
            pkgs.writeShellApplication {
              name = "flash-stlink-${fw.buildtype}";
              text = "st-flash --reset write ${fw}/bin/${fw.binary} 0x08000000";
              runtimeInputs = [ pkgs.stlink ];
            };

          jlink-script =
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
              text = "JLinkExe -commanderscript ${jlink-script fw}";
              runtimeInputs = [ jlink ];
            };

          mkProject =
            fw: mkFlash:
            pkgs.symlinkJoin {
              name = "project-output";
              paths = [
                fw
                (mkFlash fw)
              ];
              meta.mainProgram = "${(mkFlash fw).name}";
            };

          makeDebugger =
            variant:
            assert variant == "jlink" || variant == "stlink";
            pkgs.writeShellApplication {
              name = "debugger-${variant}";
              runtimeInputs = with pkgs; firmware.debug.buildInputs or [ ] ++ [ stlink ];
              text = ''
                set -x

                exe=''${1:-${firmware.debug}/bin/${firmware.debug.executable}}
                if [ -z "$exe" ]; then
                    echo "Provide executable path to .elf"
                    exit 1
                fi

                debugger="${variant}"
                if [[ "$debugger" == "jlink" ]]; then
                  port=2331
                  setsid JLinkGDBServerCLExe \
                    -device STM32F407VG \
                    -if SWD \
                    -speed ${jlinkSpeedKhz} \
                    -port "$port" \
                    > jlink.log 2>&1 &
                elif [[ "$debugger" == "stlink" ]]; then
                  port=4242
                  setsid st-util -p "$port" > stlink.log 2>&1 &
                fi

                DEBUG_SERVER_PID=$!

                # Kill J-Link server when script exits
                trap 'kill $DEBUG_SERVER_PID' EXIT

                # Give the server a moment to start
                sleep 2

                # Start GDB interactively and run commands
                exec arm-none-eabi-gdb "$exe" \
                  -ex "set confirm off" \
                  -ex "set pagination off" \
                  -ex "layout src" \
                  -ex "focus cmd" \
                  -ex "target remote localhost:$port" \
                  -ex "load" \
                  -ex "break main" \
                  -ex "continue"
              '';
            };

          debug-jlink = makeDebugger "jlink";
          debug-stlink = makeDebugger "stlink";
        in
        {
          packages = rec {
            inherit
              meson
              cmake
              debug-jlink
              debug-stlink
              ;
            default = debugger;

            debug = mkProject firmware.debug mkFlashJlink;
            release = mkProject firmware.release mkFlashJlink;
            debugst = mkProject firmware.debug mkFlashStlink;
            releasest = mkProject firmware.release mkFlashStlink;

            debugger = pkgs.symlinkJoin {
              name = "debug";
              paths = [
                debug-jlink
                firmware.debug
              ];
              meta.mainProgram = "${debug-jlink.name}";
            };
          };

          devShells.default = pkgs.mkShellNoCC {
            nativeBuildInputs =
              (firmware.debug.buildInputs or [ ])
              ++ [ jlink ]
              ++ (with pkgs; [
                clang
                clang-tools
                dos2unix
                glibc_multi
                stlink
              ]);
          };
        };
    };
}
