#include "pd_api.h"
#include "../shared/framebuffer.h"

static PlaydateAPI* pd = NULL;
uint8_t *frame_buffer = NULL;

static int update_callback(void* userdata) {
    return 0;
}

#ifdef _WINDLLa
__declspec(dllexport)
#endif // _WINDLL
int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg) {
    (void)arg;

    if (event == kEventInit) {
        pd = playdate;
        pd->system->setUpdateCallback(update_callback, NULL);
        pd->display->setRefreshRate(30);

        // Fill framebuffer with stripes demo
        frame_buffer = pd->graphics->getFrame();
        for (int y = 0; y < PD_HEIGHT; y++) {
            for (int x = 0; x < PD_BYTES_PER_ROW; x++) {
                frame_buffer[y * PD_BYTES_PER_ROW + x] = (y / 8) % 2 == 0 ? 0xFF : 0x00;
            }
        }
    }

  return 0;
}
