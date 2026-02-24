
# BlocksDS Nix Package (WIP)

This package provides a Nix-friendly development shell for building Nintendo DS games through BlocksDS.

## Usage

This derivation works by pulling the latest [official Docker image](https://hub.docker.com/r/skylyrac/blocksds) for BlocksDS and patching the programs included in it to work in a Nix environment.

To use this package, create a `flake.nix` like this:

```nix
{
  description = "Nintendo DS Flake Example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    blocksds-nix.url = "github:pgattic/blocksds-nix";
  };

  outputs = { nixpkgs, flake-utils, blocksds-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ blocksds-nix.overlays.default ];
        };
        blocksdsEnv = pkgs.blocksdsNix.blocksdsSlim.passthru;

      in {
        packages.default = pkgs.blocksdsNix.stdenvBlocksDS.mkDerivation {
          name = "my-nds-game";
          src = ./.;

          nativeBuildInputs = with pkgs; [ gnumake ];

          buildPhase = ''
            make
          '';

          installPhase = ''
            mkdir -p $out
            cp *.nds $out/
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            blocksdsNix.blocksdsSlim
            gnumake
            cmake # Some examples use CMake
            python3 # Some examples use Python
            melonds # NDS Emulator (for testing the game)
          ];

          WONDERFUL_TOOLCHAIN = blocksdsEnv.WONDERFUL_TOOLCHAIN;
          BLOCKSDS            = blocksdsEnv.BLOCKSDS;
          BLOCKSDSEXT         = blocksdsEnv.BLOCKSDSEXT;
        };
      });
}
```

Run `nix develop` to enter the provided development shell. From here, you should be able to build any BlockDS example! Follow the [BlockDS documentation](https://blocksds.skylyrac.net/docs/guides/) to start developing your game.

If this flake is included in a directory alongside a Makefile, you can just run `nix build` to compile the NDS ROM directly. If all goes well, the ROM will be placed in `result/my-nds-rom.nds`. See the [simple example](./examples/simple/) for a more complete example.

## License

This derivation is licensed under the [MIT License](./LICENSE). Please refer to the [BlocksDS license information](https://blocksds.skylyrac.net/docs/guides/licenses/) for details about BlocksDS's licensing.

## Credits

This project is possible thanks to:

- Bandithedoge for creating [https://github.com/bandithedoge/devkitNix/](devkitNix), which inspired me to make this
- AntonioND for giving us the amazing [BlocksDS](https://blocksds.skylyrac.net/)

