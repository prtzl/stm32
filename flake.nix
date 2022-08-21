{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    jlink-pack.url = "github:prtzl/jlink-nix"; # jlink debugger support
  };

  outputs = inputs:
    with inputs;
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      stdenv = pkgs.stdenv;
      jlink = jlink-pack.defaultPackage.${system};
      
      firmware = pkgs.callPackage ./default.nix { };
      
      flash-stlink = pkgs.writeShellApplication {
        name = "flash-stlink";
        text = "st-flash --reset write ${firmware}/bin/${firmware.name}.bin 0x08000000";
        runtimeInputs = [ stlink ];
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
    in {
      inherit firmware flash-jlink flash-stlink;
      
      defaultPackage.${system} = firmware;

      devShell.${system} = pkgs.mkShell {
        nativeBuildInputs = (firmware.nativeBuildInputs or [ ])
          ++ [ pkgs.clang-tools jlink pkgs.stlink pkgs.dos2unix ];
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_11.llvm ];
      };
    };
}
