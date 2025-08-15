#import "AppDelegate.h"
#import <MetalKit/MetalKit.h>
#import "MetalRenderer.h"
#include "../shared/framebuffer.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) MetalRenderer *renderer;
@end

uint8_t *frame_buffer = NULL;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();

    // Fixed window size (2x scale of 400x240)
    const NSInteger windowWidth = 800;
    const NSInteger windowHeight = 480;

    NSRect frame = NSMakeRect(0, 0, windowWidth, windowHeight);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    self.window.title = @"MyPlaydateGame — Metal Dev";
    [self.window center];

    // Prevent resizing
    self.window.styleMask &= ~NSWindowStyleMaskResizable;

    self.mtkView = [[MTKView alloc] initWithFrame:frame device:device];
    self.mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.mtkView.paused = NO;
    self.mtkView.enableSetNeedsDisplay = NO;
    self.mtkView.preferredFramesPerSecond = 60;

    // Ensure drawable size matches window pixels exactly (no Retina scaling)
    self.mtkView.layer.contentsScale = 1.0;
    self.mtkView.layer.magnificationFilter = kCAFilterNearest; // actual sampling is set in Metal

    self.renderer = [[MetalRenderer alloc] initWithView:self.mtkView];
    self.mtkView.delegate = self.renderer;

    // Allocate framebuffer and fill demo stripes
    frame_buffer = malloc(PD_BYTES_PER_ROW * PD_HEIGHT);
    for (int y = 0; y < PD_HEIGHT; y++) {
        for (int x = 0; x < PD_BYTES_PER_ROW; x++) {
            frame_buffer[y * PD_BYTES_PER_ROW + x] = (y / 8) % 2 == 0 ? 0xFF : 0x00;
        }
    }
    [self.renderer setFrameBufferPointer:frame_buffer];

    self.window.contentView = self.mtkView;
    [self.window makeKeyAndOrderFront:nil];


}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}
@end
