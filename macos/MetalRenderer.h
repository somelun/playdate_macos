#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

@interface MetalRenderer : NSObject <MTKViewDelegate>
- (instancetype)initWithView:(MTKView *)view;
// Supply (or update) the 1-bpp framebuffer pointer at runtime (optional).
- (void)setFrameBufferPointer:(uint8_t *)ptr;
@end
