#include "../game_logic.h"
#include <stdio.h>
#include <nds.h>

int main(int argc, char **argv) {
    consoleDemoInit();

    int result = do_game_logic(2, 2);

    printf("The answer is... %d\n", result);

    printf("Press START to exit to loader\n");

    while (1) {
        swiWaitForVBlank();

        scanKeys();

        if (keysDown() & KEY_START) break;
    }

    return 0;
}

