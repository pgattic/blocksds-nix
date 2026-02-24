
# Nintendo DS Cross-Platform (CMake) Example

This example showcases building a cross-platform game using CMake, targeting NDS and Linux.

## Build Steps

- Build the NDS ROM with `nix build .` (the `#nds` target is set as the default in the flake)
    - ROM will be placed in `result/portable-demo.nds`
- Build the Linux Program with `nix build .#linux`
    - Program will be placed in `result/bin/portable-demo`

## Dev Shell

- `nix develop`
- Compile for NDS:
    - `cmake -S . -B build/nds -DCMAKE_TOOLCHAIN_FILE="$BLOCKSDS/cmake/BlocksDS.cmake"`
    - `cmake --build build/nds`
- Compile for Linux:
    - `cmake -S . -B build/linux`
    - `cmake --build build/linux`

