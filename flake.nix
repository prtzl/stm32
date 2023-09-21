{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    jlink-pack = {
      url = "github:prtzl/jlink-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      stdenv = pkgs.stdenv;
      jlink = inputs.jlink-pack.defaultPackage.${system}.overrideAttrs (attrs: {
        meta.license = "";
      });

      firmware = pkgs.callPackage ./default.nix { };

      flash-stlink = pkgs.writeShellApplication {
        name = "flash-stlink";
        text = "st-flash --reset write ${firmware}/bin/${firmware.name}.bin 0x08000000";
        runtimeInputs = [ pkgs.stlink ];
      };

      jlink-script = pkgs.writeTextFile {
        name = "jlink-script";
        text = ''
          device ${firmware.device}
          si 1
          speed 4000
          loadfile ${firmware}/bin/${firmware.name}.bin,0x08000000
          r
          g
          qc
        '';
      };

      flash-jlink = pkgs.writeShellApplication {
        name = "flash-jlink";
        text = "JLinkExe -commanderscript ${jlink-script}";
        runtimeInputs = [ jlink ];
      };
    in
    {
      inherit firmware flash-jlink flash-stlink;

      defaultPackage = firmware;
      defaultApp = flash-jlink;

      devShell = pkgs.mkShellNoCC {
        nativeBuildInputs = (firmware.nativeBuildInputs or [ ]) ++ (firmware.buildInputs or [ ])
          ++ [ pkgs.clang-tools jlink pkgs.stlink pkgs.dos2unix pkgs.glibc_multi pkgs.clang ];
      };
    });
}
