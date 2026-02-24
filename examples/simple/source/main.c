#include <stdio.h>
#include <nds.h>

int main(int argc, char **argv) {
  consoleDemoInit();

  while (1) {
    // Synchronize game loop to the screen refresh
    swiWaitForVBlank();

    consoleClear();

    // Print some controls
    printf("This program was built with BlocksDS using Nix!\n");
    printf("START: Exit to loader\n");

    scanKeys();
    uint16_t keys = keysHeld();

    if (keys & KEY_START) break;
  }

  return 0;
}

