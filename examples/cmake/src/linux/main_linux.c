#include "../game_logic.h"
#include <stdio.h>

int main(int argc, char **argv) {
    int result = do_game_logic(2, 2);

    printf("The answer is... %d\n", result);

    return 0;
}

