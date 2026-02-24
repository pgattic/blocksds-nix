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
        blocksdsEnv = pkgs.blocksdsNix.stdenvBlocksdsSlim;

      in {
        packages.default = blocksdsEnv.mkDerivation {
          pname = "simple-example";
          version = "0.1.0";
          src = ./.;

          buildPhase = ''
            ${pkgs.gnumake}/bin/make
          '';

          installPhase = ''
            mkdir -p $out
            cp *.nds $out/
          '';
        };

        devShells.default = pkgs.blocksdsNix.mkShell {
          packages = with pkgs; [
            gnumake
          ];

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

