
# Nintendo DS Cross-Platform (CMake) Example

This example showcases building a cross-platform game using CMake, targeting NDS, DSi, and Linux.

## Build Steps

- Build the NDS ROM with `nix build .` (the `#nds` target is set as the default in the flake)
    - ROM will be placed in `result/portable-demo.nds`
- Build the DSi ROM with `nix build .#dsi`
    - ROM will be placed in `result/portable-demo.nds`
- Build the Linux Program with `nix build .#linux`
    - Program will be placed in `result/bin/portable-demo`

## Dev Shell

- `nix develop`
- Compile for NDS:
    - `cmake -S . -B build/nds -DCMAKE_TOOLCHAIN_FILE="$BLOCKSDS/cmake/BlocksDS.cmake"`
    - (Swap `BlocksDS.cmake` with `BlocksDSi.cmake` to target DSi)
    - `cmake --build build/nds`
- Compile for Linux:
    - `cmake -S . -B build/linux`
    - `cmake --build build/linux`

