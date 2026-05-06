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

          tools = import ./nix { inherit pkgs jlink; };

          inherit (tools)
            firmware
            flash
            debug
            buildTools
            ;
        in
        {
          packages =
            let
              defaultFlash = pkgs.writeShellScriptBin "flash-default" ''
                exec ${flash.flash-jlink}/bin/flash-jlink ${firmware.debug}/bin/${firmware.debug.executable}
              '';

              default = pkgs.symlinkJoin {
                name = "flash-debug";
                paths = [
                  firmware.debug
                  defaultFlash
                ];
                meta.mainProgram = defaultFlash.name;
              };
            in
            {
              inherit (debug) debug-jlink debug-stlink;
              inherit (flash) flash-jlink flash-stlink;
              inherit (buildTools) meson cmake;

              inherit default;
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
