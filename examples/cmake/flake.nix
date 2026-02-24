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
        blocksdsEnv = pkgs.blocksdsNix.stdenvBlocksdsSlim;

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

            configurePhase = ''
              ${pkgs.cmake}/bin/cmake -S . -B build/linux \
                ${pkgs.lib.concatStringsSep " " cmakeCommon}
            '';

            buildPhase = ''
              ${pkgs.cmake}/bin/cmake --build build/linux
            '';

            installPhase = ''
              mkdir -p $out/bin
              # Adjust if your target name differs
              cp -v build/linux/portable-demo $out/bin/
            '';
          };

          nds = blocksdsEnv.mkDerivation {
            pname = "portable-demo-nds";
            version = "0.1.0";
            src = ./.;

            configurePhase = ''
              ${pkgs.cmake}/bin/cmake -S . -B build/nds \
                ${pkgs.lib.concatStringsSep " " cmakeCommon} \
                -DCMAKE_TOOLCHAIN_FILE="$BLOCKSDS/cmake/BlocksDS.cmake"
            '';

            buildPhase = ''
              ${pkgs.cmake}/bin/cmake --build build/nds
            '';

            installPhase = ''
              mkdir -p $out
              cp build/nds/*.nds $out/
            '';
          };

          dsi = blocksdsEnv.mkDerivation {
            pname = "portable-demo-dsi";
            version = "0.1.0";
            src = ./.;

            configurePhase = ''
              ${pkgs.cmake}/bin/cmake -S . -B build/dsi \
                ${pkgs.lib.concatStringsSep " " cmakeCommon} \
                -DCMAKE_TOOLCHAIN_FILE="$BLOCKSDS/cmake/BlocksDSi.cmake"
            '';

            buildPhase = ''
              ${pkgs.cmake}/bin/cmake --build build/dsi
            '';

            installPhase = ''
              mkdir -p $out
              cp build/dsi/*.nds $out/
            '';
          };

          # Pick what `nix build` produces by default.
          default = nds;
        };

        devShells.default = pkgs.blocksdsNix.mkShell {
          packages = with pkgs; [
            cmake
            gnumake
            gcc
            gdb
          ];

          shellHook = ''
            echo "Dev shell: BlocksDS + Linux portable demo"
            echo ""
            echo "Linux build:"
            echo "  cmake -S . -B build/linux -DCMAKE_BUILD_TYPE=Release"
            echo "  cmake --build build/linux"
            echo ""
            echo "NDS build:"
            echo "  cmake -S . -B build/nds -DCMAKE_BUILD_TYPE=Release \\"
            echo "    -DCMAKE_TOOLCHAIN_FILE=\"$BLOCKSDS/cmake/BlocksDS.cmake\""
            echo "  cmake --build build/nds"
            echo ""
            echo "DSi build:"
            echo "  cmake -S . -B build/dsi -DCMAKE_BUILD_TYPE=Release \\"
            echo "    -DCMAKE_TOOLCHAIN_FILE=\"$BLOCKSDS/cmake/BlocksDSi.cmake\""
            echo "  cmake --build build/dsi"
            echo ""
            echo "Docs: https://blocksds.skylyrac.net/docs/guides/"
          '';
        };
      }
    );
}

