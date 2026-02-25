{
  description = "BlocksDS Nix Package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }: let
    mkBlocksDS = pkgs: { name, srcJson }: let
      imageTar = pkgs.dockerTools.pullImage (pkgs.lib.importJSON srcJson);
      arch = if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
        then "x86_64"
        else "aarch64";
    in pkgs.stdenv.mkDerivation (finalAttrs: {
      inherit name;
      src = imageTar;

      nativeBuildInputs = with pkgs; [
        jq
        auto-patchelf
        patchelf
      ];

      buildInputs = with pkgs; [
        ncurses
        stdenv.cc.cc.lib
      ];

      dontPatchShebangs = true;

      phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

      unpackPhase = ''
        # Unpack the docker archive (this gives us manifest.json + layer tarballs)
        tar -xf "$src"
      '';

      installPhase = ''
        mkdir -p rootfs

        layers="$(jq -r '.[0].Layers[]' manifest.json)"

        # Extract layers and delete some unnecessary stuff
        for layer in $layers; do
          # 1) Process whiteouts in this layer tar
          # - .wh.<name> means "delete <name> from lower layers"
          # - .wh..wh..opq means "directory is opaque": clear existing contents
          while IFS= read -r p; do
            base="$(basename "$p")"
            dir="$(dirname "$p")"

            if [ "$base" = ".wh..wh..opq" ]; then
              # Opaque directory: remove all existing contents of that directory
              rm -rf "rootfs/$dir"/*
            else
              # Regular whiteout: delete the referenced path
              target="$dir/''${base#.wh.}"
              rm -rf "rootfs/$target"
            fi
          done < <(tar -tf "$layer" | grep -E '(^|/)\.wh\.' || true)

          # 2) Extract layer contents excluding whiteout marker files
          tar -xf "$layer" -C rootfs --exclude='*.wh.*'
        done

        # Copy payload into $out
        mkdir -p "$out"
        cp -a rootfs/opt "$out/opt"
        ln -sfn "$out/opt/wonderful/bin" "$out/bin"
        auto-patchelf -- "''${out}/bin" || true

        # Patch binaries to point to the correct places within the nix store
        musl_ld="$out/opt/wonderful/lib/ld-musl-${arch}.so.1"
        musl_lib="$out/opt/wonderful/lib"

        patch_musl_tree() {
          dir="$1"
          [ -d "$dir" ] || return 0

          # Find executables and shared objects; patch only those that reference /opt/wonderful musl loader
          while IFS= read -r f; do
            if file -b "$f" | grep -q 'ELF'; then
              # Only patch things that still point at the hardcoded docker path
              if patchelf --print-interpreter "$f" 2>/dev/null | grep -q '^/opt/wonderful/lib/ld-musl-${arch}.so.1$'; then
                patchelf --set-interpreter "$musl_ld" "$f"
                # Ensure it can find musl-linked libs shipped in the SDK
                patchelf --set-rpath "$musl_lib" "$f" || true
              fi
            fi
          done < <(find "$dir" -type f \( -perm -0100 -o -name '*.so*' \))
        }

        patch_musl_tree "$out/opt/wonderful/toolchain/gcc-arm-none-eabi/bin"
        patch_musl_tree "$out/opt/wonderful/toolchain/gcc-arm-none-eabi/libexec"
        patch_musl_tree "$out/opt/wonderful/bin"
        patch_musl_tree "$out/opt/wonderful/thirdparty/blocksds/core/tools"
      '';

      passthru = rec {
        WONDERFUL_TOOLCHAIN = "${finalAttrs.finalPackage}/opt/wonderful";
        BLOCKSDS            = "${WONDERFUL_TOOLCHAIN}/thirdparty/blocksds/core";
        BLOCKSDSEXT         = "${WONDERFUL_TOOLCHAIN}/thirdparty/blocksds/external";
      };
    });
    packagesFor = pkgs: rec {
      blocksdsSlim = mkBlocksDS pkgs {
        name = "blocksds-slim";
        srcJson = if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
          then ./sources/blocksds-slim-amd64.json
          else ./sources/blocksds-slim-arm64.json;
      };

      blocksdsDev = mkBlocksDS pkgs {
        name = "blocksds-dev";
        srcJson = if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
          then ./sources/blocksds-dev-amd64.json
          else ./sources/blocksds-dev-arm64.json;
      };

      # "Build environment" wrappers
      stdenvBlocksdsSlim = pkgs.stdenvAdapters.addAttrsToDerivation {
        nativeBuildInputs = [ blocksdsSlim ];
        strictDeps = false;
        env = {
          WONDERFUL_TOOLCHAIN = blocksdsSlim.passthru.WONDERFUL_TOOLCHAIN;
          BLOCKSDS            = blocksdsSlim.passthru.BLOCKSDS;
          BLOCKSDSEXT         = blocksdsSlim.passthru.BLOCKSDSEXT;
        };
      } pkgs.stdenvNoCC;

      stdenvBlocksdsDev = pkgs.stdenvAdapters.addAttrsToDerivation {
        nativeBuildInputs = [ blocksdsDev ];
        strictDeps = false;
        env = {
          WONDERFUL_TOOLCHAIN = blocksdsDev.passthru.WONDERFUL_TOOLCHAIN;
          BLOCKSDS            = blocksdsDev.passthru.BLOCKSDS;
          BLOCKSDSEXT         = blocksdsDev.passthru.BLOCKSDSEXT;
        };
      } pkgs.stdenvNoCC;

      mkShell = { stdenv ? stdenvBlocksdsSlim
                , packages ? []
                , nativeBuildInputs ? []
                , buildInputs ? []
                , ... }@args:
        pkgs.mkShell (args // {
          inherit stdenv;
          # ensure "packages" are actually on PATH
          nativeBuildInputs = nativeBuildInputs ++ packages;
          packages = [];
          buildInputs = buildInputs;
        });
    };
  in (flake-utils.lib.eachDefaultSystem (system:
    let pkgs = nixpkgs.legacyPackages.${system};
    in { packages = packagesFor pkgs; }
  ))
  // {
    overlays.default = final: prev: {
      blocksdsNix = packagesFor prev;
    };
  };
}

