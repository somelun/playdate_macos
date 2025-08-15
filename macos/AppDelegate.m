#import "AppDelegate.h"
#import <MetalKit/MetalKit.h>
#import "MetalRenderer.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) MetalRenderer *renderer;
@end

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

    self.window.contentView = self.mtkView;
    [self.window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}
@end
