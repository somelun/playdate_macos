#include "framebuffer.h"
#include <stdlib.h>

uint8_t *frame_buffer = NULL;

__attribute__((constructor)) static void init_framebuffer() {
    frame_buffer = calloc(PD_BYTES_PER_ROW * PD_HEIGHT, 1);
    for (int y = 0; y < PD_HEIGHT; ++y) {
        for (int x = 0; x < PD_BYTES_PER_ROW; ++x) {
            frame_buffer[y * PD_BYTES_PER_ROW + x] = (y & 8) ? 0xFF : 0x00;
        }
    }
}
