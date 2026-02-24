
# BlocksDS Nix Package

This package provides a Nix-friendly development shell for building Nintendo DS games through BlocksDS.

This derivation works by pulling the latest [official Docker image](https://hub.docker.com/r/skylyrac/blocksds) for BlocksDS and patching the programs included in it to work in a Nix environment.

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    blocksds-nix = {
      url = "github:pgattic/blocksds-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, blocksds-nix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ blocksds-nix.overlays.default ];
      };
      blocksds = pkgs.blocksdsNix.blocksdsSlim;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ blocksds ];

        WONDERFUL_TOOLCHAIN = blocksds.passthru.WONDERFUL_TOOLCHAIN;
        BLOCKSDS            = blocksds.passthru.BLOCKSDS;
        BLOCKSDSEXT         = blocksds.passthru.BLOCKSDSEXT;
      };
    };
}
```

See the [simple example](./examples/simple/) for a more complete usecase. If you want your game to target multiple platforms, see the [CMake example](./examples/cmake/) which demonstrates sharing source code between Nintendo DS, DSi, and Linux.

## License

This repository's code is licensed under the [MIT License](./LICENSE). Please refer to the [BlocksDS license information](https://blocksds.skylyrac.net/docs/guides/licenses/) for details about BlocksDS's licensing.

## Credits

This project is possible thanks to:

- Bandithedoge for creating [devkitNix](https://github.com/bandithedoge/devkitNix/), which inspired me to make this
- AntonioND for giving us the amazing [BlocksDS](https://blocksds.skylyrac.net/)

