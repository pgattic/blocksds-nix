{
  description = "Nintendo DS Package Example";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    flake-parts.url = "github:hercules-ci/flake-parts";
    blocksds-nix = {
      url = "github:pgattic/blocksds-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs = inputs@{ nixpkgs, flake-parts, blocksds-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem = { system, ... }:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ blocksds-nix.overlays.default ];
        };
        blocksds = pkgs.blocksdsNix.blocksdsSlim;
        blocksdsEnv = blocksds.passthru;

      in {
        packages.default = pkgs.blocksdsNix.stdenvBlocksdsSlim.mkDerivation {
          pname = "simple-example";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.gnumake ];

          buildPhase = ''
            make
          '';

          installPhase = ''
            mkdir -p $out
            cp *.nds $out/
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = [
            blocksds
            pkgs.gnumake
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
      };
    };
}
