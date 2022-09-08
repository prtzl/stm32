{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    jlink-pack = {
      url = "/home/matej/projects/jlink-pack";
      #url = "github:prtzl/jlink-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      stdenv = pkgs.stdenv;
      jlink = inputs.jlink-pack.defaultPackage.${system}.overrideAttrs (attrs: {
        meta.licence = null;
      });

      firmware = pkgs.callPackage ./default.nix { };
      
      flash-stlink = pkgs.writeShellApplication {
        name = "flash-stlink";
        text = "st-flash --reset write ${firmware}/bin/${firmware.name}.bin 0x08000000";
        runtimeInputs = [ pkgs.stlink ];
      };

      jlink-script = with inputs.jlink-pack; make-script {
        device = "${firmware.device}";
        fpath = "${firmware}/bin/${firmware.name}.bin";
      };
      flash-jlink = inputs.jlink-pack.flash-script jlink-script;
    in
    {
      inherit firmware flash-stlink flash-jlink;

      defaultPackage = firmware;
      defaultApp = flash-jlink;

      devShell = pkgs.mkShell {
        nativeBuildInputs = (firmware.nativeBuildInputs or [ ])
          ++ [ pkgs.clang-tools jlink pkgs.stlink pkgs.dos2unix ];
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_11.llvm ];
      };
  });
}
