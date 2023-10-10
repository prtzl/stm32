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

      firmware.base = { buildtype }: pkgs.callPackage ./default.nix { inherit buildtype; };
      firmware.debug = firmware.base { buildtype = "Debug"; };
      firmware.release = firmware.base { buildtype = "Release"; };

      flash-stlink.base = fw: pkgs.writeShellApplication {
        name = "flash-stlink ${fw.buildType}";
        text = "st-flash --reset write ${fw}/bin/${fw.binary}.bin 0x08000000";
        runtimeInputs = [ pkgs.stlink ];
      };
      flash-stlink.debug = flash-stlink.base firmware.debug;
      flash-stlink.release = flash-stlink.base firmware.release;

      jlink-script = fw: pkgs.writeTextFile {
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

      flash-jlink.base = fw: pkgs.writeShellApplication {
        name = "flash-jlink";
        text = "JLinkExe -commanderscript ${jlink-script fw}";
        runtimeInputs = [ jlink ];
      };
      flash-jlink.debug = flash-jlink.base firmware.debug;
      flash-jlink.release = flash-jlink.base firmware.release;
    in
    {
      packages = {
        inherit firmware;
        default = firmware.debug;
      };

      apps = {
        inherit flash-jlink flash-stlink;
        default = flash-jlink.debug;
      };

      devShell = pkgs.mkShellNoCC {
        nativeBuildInputs = (firmware.debug.buildInputs or [ ])
          ++ [ pkgs.clang-tools jlink pkgs.stlink pkgs.dos2unix pkgs.glibc_multi pkgs.clang ];
      };
    });
}
