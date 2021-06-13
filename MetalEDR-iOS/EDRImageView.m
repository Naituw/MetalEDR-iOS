//
//  EDRImageView.m
//  MetalEDR-iOS
//
//  Created by Wu Tian on 2021/6/12.
//

#import <MetalKit/MetalKit.h>
#import "EDRImageView.h"
#import "EDRImageShaderTypes.h"

@interface EDRMetalView : MTKView
{
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLSamplerState> _samplerState;
}

@property (nonatomic, strong) id<MTLTexture> texture;

@end

@implementation EDRMetalView

- (instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device
{
    if (self = [super initWithFrame:frameRect device:device]) {
        self.colorPixelFormat = MTLPixelFormatRGBA16Float;
        self.enableSetNeedsDisplay = YES;
        self.autoResizeDrawable = YES;
        self.clearColor = MTLClearColorMake(0, 0, 0, 1);
        
        NSError *error;

        id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];

        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

        // Configure a pipeline descriptor that is used to create a pipeline state.
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Simple Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;

        _pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];
                
        // Pipeline State creation could fail if the pipeline descriptor isn't set up properly.
        //  If the Metal API validation is enabled, you can find out more information about what
        //  went wrong.  (Metal API validation is enabled by default when a debug build is run
        //  from Xcode.)
        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
        
        _commandQueue = [device newCommandQueue];
        
        MTLSamplerDescriptor * samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
        samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
        _samplerState = [device newSamplerStateWithDescriptor:samplerDescriptor];
    }
    return self;
}

- (void)setTexture:(id<MTLTexture>)texture
{
    if (_texture != texture) {
        _texture = texture;
        
        [self setNeedsDisplay];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setNeedsDisplay];
        });
    }
}

- (void)drawRect:(CGRect)rect
{
    CGSize size = self.drawableSize;

    static const EDRImageVertex triangleVertices[] = {
        // 2D positions, TextureCoords
        { {  -1,  -1 }, { 0, 1 } },
        { {  -1,   1 }, { 0, 0 } },
        { {   1,  -1 }, { 1, 1 } },
        { {   1,   1 }, { 1, 0 } },
    };

    // Create a new command buffer for each render pass to the current drawable.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
        
    // Obtain a renderPassDescriptor generated from the view's drawable textures.
    MTLRenderPassDescriptor *renderPassDescriptor = self.currentRenderPassDescriptor;

    if (renderPassDescriptor != nil) {
        // Create a render command encoder.
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set the region of the drawable to draw into.
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, size.width, size.height, 0.0, 1.0 }];
        
        [renderEncoder setRenderPipelineState:_pipelineState];

        // Pass in the parameter data.
        [renderEncoder setVertexBytes:triangleVertices
                               length:sizeof(triangleVertices)
                              atIndex:0];
                
        [renderEncoder setFragmentTexture:_texture atIndex:0];
        [renderEncoder setFragmentSamplerState:_samplerState atIndex:0];

        // Draw the triangle.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                          vertexStart:0
                          vertexCount:4];

        [renderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable.
        [commandBuffer presentDrawable:self.currentDrawable];
    }

    // Finalize rendering here & push the command buffer to the GPU.
    [commandBuffer commit];
}

@end

@interface EDRImageView ()

@property (nonatomic, strong) id<MTLDevice> metalDevice;
@property (nonatomic, strong) EDRMetalView * metalView;

@end

@implementation EDRImageView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self addSubview:self.metalView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.metalView];
    }
    return self;
}

- (id<MTLDevice>)metalDevice
{
    if (!_metalDevice) {
        _metalDevice = MTLCreateSystemDefaultDevice();
    }
    return _metalDevice;
}

- (EDRMetalView *)metalView
{
    if (!_metalView) {
        _metalView = [[EDRMetalView alloc] initWithFrame:self.bounds device:self.metalDevice];
    }
    return _metalView;
}

- (void)setImage:(UIImage *)image
{
    if (_image != image) {
        _image = image;
        
        id<MTLTexture> texture = nil;
        
        if (image.CGImage) {
            CGImageRef img = image.CGImage;
            
            size_t width  = CGImageGetWidth(img);
            size_t height = CGImageGetHeight(img);

            CGBitmapInfo info = kCGBitmapByteOrder16Host | kCGImageAlphaPremultipliedLast | kCGBitmapFloatComponents;

            CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 16, 0, CGColorSpaceCreateWithName(kCGColorSpaceExtendedLinearSRGB), info);

            CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), img);

            // Create floating point texture

            MTLTextureDescriptor* desc = [[MTLTextureDescriptor alloc] init];
            desc.pixelFormat = MTLPixelFormatRGBA16Float;
            desc.textureType = MTLTextureType2D;
            desc.width = width;
            desc.height = height;

            id<MTLTexture> tex = [self.metalDevice newTextureWithDescriptor:desc];

            // Load EDR bitmap into texture

            const void * data = CGBitmapContextGetData(ctx);

            [tex replaceRegion:MTLRegionMake2D(0, 0, width, height)
                   mipmapLevel:0
                     withBytes:data
                   bytesPerRow:CGBitmapContextGetBytesPerRow(ctx)];
            
            texture = tex;
        }
        _metalView.texture = texture;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _metalView.frame = self.bounds;
    [_metalView setNeedsDisplay];
}

@end
