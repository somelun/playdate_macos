#import "MetalRenderer.h"
#import <simd/simd.h>
#import "framebuffer.h"

// Set to 2 for 800x480 window, or change the window size in AppDelegate instead.
static const int SCALE = 2;

// If your bit convention is opposite, define PD_INVERT_PIXELS at build time or flip here.
#ifndef PD_INVERT_PIXELS
#define PD_INVERT_PIXELS 0
#endif

typedef struct {
    vector_float2 position; // clip space
    vector_float2 uv;       // 0..1
} Vertex;

@interface MetalRenderer ()
@property (nonatomic, weak) MTKView *view;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLTexture> texture;      // R8Unorm grayscale 400x240
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLSamplerState> sampler;
@property (nonatomic, strong) NSMutableData *expandedRow;  // temp row buffer for uploads
@property (nonatomic) uint8_t *externalFB;                 // optional external pointer
@end

@implementation MetalRenderer

- (instancetype)initWithView:(MTKView *)view {
    if ((self = [super init])) {
        _view = view;
        _device = view.device;
        _commandQueue = [_device newCommandQueue];

        // Fullscreen quad covering the view, UVs map to 400x240 texture
        const Vertex quad[6] = {
            { .position = {-1.0f, -1.0f}, .uv = {0.0f, 1.0f} },
            { .position = { 1.0f, -1.0f}, .uv = {1.0f, 1.0f} },
            { .position = {-1.0f,  1.0f}, .uv = {0.0f, 0.0f} },
            { .position = { 1.0f, -1.0f}, .uv = {1.0f, 1.0f} },
            { .position = { 1.0f,  1.0f}, .uv = {1.0f, 0.0f} },
            { .position = {-1.0f,  1.0f}, .uv = {0.0f, 0.0f} },
        };
        _vertexBuffer = [_device newBufferWithBytes:quad length:sizeof(quad) options:MTLResourceStorageModeManaged];

        NSError *err = nil;
        id<MTLLibrary> lib = [_device newDefaultLibrary];
        id<MTLFunction> vtx = [lib newFunctionWithName:@"vert_main"];
        id<MTLFunction> frg = [lib newFunctionWithName:@"frag_main"];

        MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
        desc.vertexFunction = vtx;
        desc.fragmentFunction = frg;
        desc.colorAttachments[0].pixelFormat = _view.colorPixelFormat;
        _pipeline = [_device newRenderPipelineStateWithDescriptor:desc error:&err];
        NSCAssert(_pipeline, @"Pipeline error: %@", err);

        MTLSamplerDescriptor *samp = [[MTLSamplerDescriptor alloc] init];
        samp.minFilter = MTLSamplerMinMagFilterNearest;
        samp.magFilter = MTLSamplerMinMagFilterNearest;
        samp.sAddressMode = MTLSamplerAddressModeClampToEdge;
        samp.tAddressMode = MTLSamplerAddressModeClampToEdge;
        _sampler = [_device newSamplerStateWithDescriptor:samp];

        // Create 8-bit grayscale texture (R8)
        MTLTextureDescriptor *td = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                                                       width:PD_WIDTH
                                                                                      height:PD_HEIGHT
                                                                                   mipmapped:NO];
        td.usage = MTLTextureUsageShaderRead | MTLTextureUsagePixelFormatView;
        _texture = [_device newTextureWithDescriptor:td];

        _expandedRow = [NSMutableData dataWithLength:PD_WIDTH];
        _externalFB = NULL; // will use extern frame_buffer if available

        // Set initial drawable size for nearest-neighbor scaling
        view.drawableSize = CGSizeMake(PD_WIDTH * SCALE, PD_HEIGHT * SCALE);
    }
    return self;
}

- (void)setFrameBufferPointer:(uint8_t *)ptr {
    _externalFB = ptr;
}

// Expand one 1-bpp row (52 bytes) into 400 bytes (0..255), MSB-first.
static inline void expandRow(const uint8_t *srcRow, uint8_t *dstRow) {
    int x = 0;
    for (int b = 0; b < PD_BYTES_PER_ROW; ++b) {
        uint8_t byte = srcRow[b];
        for (int bit = 7; bit >= 0 && x < PD_WIDTH; --bit, ++x) {
            uint8_t bitOn = (byte >> bit) & 1u;
#if PD_INVERT_PIXELS
            dstRow[x] = bitOn ? 255 : 0; // 1 = white
#else
            dstRow[x] = bitOn ? 0 : 255; // 1 = black (Playdate typical)
#endif
        }
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size { (void)view; (void)size; }

- (void)drawInMTKView:(MTKView *)view {
    uint8_t *src = _externalFB ? _externalFB : frame_buffer; // prefer explicit pointer if set
    if (src) {
        // Upload each row
        for (int y = 0; y < PD_HEIGHT; ++y) {
            const uint8_t *srcRow = src + y * PD_BYTES_PER_ROW;
            uint8_t *dstRow = (uint8_t *)_expandedRow.mutableBytes;
            expandRow(srcRow, dstRow);
            MTLRegion r = MTLRegionMake2D(0, y, PD_WIDTH, 1);
            [_texture replaceRegion:r mipmapLevel:0 withBytes:dstRow bytesPerRow:PD_WIDTH];
        }
    }

    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!drawable) return;

    MTLRenderPassDescriptor *rp = view.currentRenderPassDescriptor;
    if (!rp) return;

    id<MTLCommandBuffer> cb = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cb renderCommandEncoderWithDescriptor:rp];

    [enc setRenderPipelineState:self.pipeline];
    [enc setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [enc setFragmentTexture:self.texture atIndex:0];
    [enc setFragmentSamplerState:self.sampler atIndex:0];

    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [enc endEncoding];

    [cb presentDrawable:drawable];
    [cb commit];
}
@end
