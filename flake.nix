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
            mkProject
            ;
        in
        {
          packages = {
            inherit (debug) debug-jlink debug-stlink;
            inherit (buildTools) meson cmake;

            flash-stlink = flash.flashStlink;
            flash-jlink = flash.flashJlink;
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
