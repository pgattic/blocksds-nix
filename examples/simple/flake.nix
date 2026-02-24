{
  description = "Nintendo DS Package Example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    blocksds-nix = {
      url = "github:pgattic/blocksds-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, blocksds-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ blocksds-nix.overlays.default ];
        };
        blocksds = pkgs.blocksdsNix.blocksdsSlim;
        blocksdsEnv = blocksds.passthru;

      in {
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          name = "simple-example";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            blocksds
            gnumake
          ];

          buildPhase = ''
            make
          '';

          installPhase = ''
            mkdir -p $out
            cp *.nds $out/
          '';

          WONDERFUL_TOOLCHAIN = blocksdsEnv.WONDERFUL_TOOLCHAIN;
          BLOCKSDS            = blocksdsEnv.BLOCKSDS;
          BLOCKSDSEXT         = blocksdsEnv.BLOCKSDSEXT;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            blocksds
            gnumake
          ];

          WONDERFUL_TOOLCHAIN = blocksdsEnv.WONDERFUL_TOOLCHAIN;
          BLOCKSDS            = blocksdsEnv.BLOCKSDS;
          BLOCKSDSEXT         = blocksdsEnv.BLOCKSDSEXT;

          shellHook = ''
            echo "Welcome to the Nintendo DS example dev shell!"
            echo "Type \"make\" to compile the ROM"
            echo ""
            echo "Read the BlocksDS documentation to learn how to use BlocksDS:"
            echo "https://blocksds.skylyrac.net/docs/guides/"
          '';
        };
      });
}

