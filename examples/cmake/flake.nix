{
  description = "BlocksDS + Linux portable CMake example";

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

        # Shared CMake flags
        cmakeCommon = [
          "-DCMAKE_BUILD_TYPE=Release"
          "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
        ];
      in
      {
        packages = rec {
          # Native Linux build
          linux = pkgs.stdenv.mkDerivation {
            pname = "portable-demo-linux";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              cmake
              ninja
            ];

            configurePhase = ''
              cmake -S . -B build/linux -G Ninja \
                ${pkgs.lib.concatStringsSep " " cmakeCommon}
            '';

            buildPhase = ''
              cmake --build build/linux
            '';

            installPhase = ''
              mkdir -p $out/bin
              # Adjust if your target name differs
              cp -v build/linux/portable-demo $out/bin/
            '';
          };

          nds = pkgs.stdenvNoCC.mkDerivation {
            pname = "portable-demo-nds";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              blocksds
              cmake
              ninja
            ];

            # Provide the SDK env vars the BlocksDS toolchain expects
            WONDERFUL_TOOLCHAIN = blocksdsEnv.WONDERFUL_TOOLCHAIN;
            BLOCKSDS            = blocksdsEnv.BLOCKSDS;
            BLOCKSDSEXT         = blocksdsEnv.BLOCKSDSEXT;

            configurePhase = ''
              cmake -S . -B build/nds -G Ninja \
                ${pkgs.lib.concatStringsSep " " cmakeCommon} \
                -DCMAKE_TOOLCHAIN_FILE="$BLOCKSDS/cmake/BlocksDS.cmake"
            '';

            buildPhase = ''
              cmake --build build/nds
            '';

            installPhase = ''
              mkdir -p $out
              cp build/nds/*.nds $out/
            '';
          };

          dsi = pkgs.stdenvNoCC.mkDerivation {
            pname = "portable-demo-dsi";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              blocksds
              cmake
              ninja
            ];

            # Provide the SDK env vars the BlocksDS toolchain expects
            WONDERFUL_TOOLCHAIN = blocksdsEnv.WONDERFUL_TOOLCHAIN;
            BLOCKSDS            = blocksdsEnv.BLOCKSDS;
            BLOCKSDSEXT         = blocksdsEnv.BLOCKSDSEXT;

            configurePhase = ''
              cmake -S . -B build/nds -G Ninja \
                ${pkgs.lib.concatStringsSep " " cmakeCommon} \
                -DCMAKE_TOOLCHAIN_FILE="$BLOCKSDS/cmake/BlocksDSi.cmake"
            '';

            buildPhase = ''
              cmake --build build/nds
            '';

            installPhase = ''
              mkdir -p $out
              cp build/nds/*.nds $out/
            '';
          };

          # Pick what `nix build` produces by default.
          default = nds;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            blocksds
            cmake
            ninja
            gcc
            gdb
          ];

          WONDERFUL_TOOLCHAIN = blocksdsEnv.WONDERFUL_TOOLCHAIN;
          BLOCKSDS            = blocksdsEnv.BLOCKSDS;
          BLOCKSDSEXT         = blocksdsEnv.BLOCKSDSEXT;

          shellHook = ''
            echo "Dev shell: BlocksDS + Linux portable demo"
            echo ""
            echo "Linux build:"
            echo "  cmake -S . -B build/linux -G Ninja -DCMAKE_BUILD_TYPE=Release"
            echo "  cmake --build build/linux"
            echo ""
            echo "NDS build:"
            echo "  cmake -S . -B build/nds -G Ninja -DCMAKE_BUILD_TYPE=Release \\"
            echo "    -DCMAKE_TOOLCHAIN_FILE=\"$BLOCKSDS/cmake/BlocksDS.cmake\""
            echo "  cmake --build build/nds"
            echo ""
            echo "DSi build:"
            echo "  cmake -S . -B build/nds -G Ninja -DCMAKE_BUILD_TYPE=Release \\"
            echo "    -DCMAKE_TOOLCHAIN_FILE=\"$BLOCKSDS/cmake/BlocksDSi.cmake\""
            echo "  cmake --build build/nds"
            echo ""
            echo "Docs: https://blocksds.skylyrac.net/docs/guides/"
          '';
        };
      }
    );
}

