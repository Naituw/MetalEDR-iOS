# MetalEDR-iOS
Demo of using Metal to render EDR/HDR content on iOS platform.

https://user-images.githubusercontent.com/353943/121794328-c679b800-cc39-11eb-8a9b-c8a7de5d53f6.mov

## How it works

This demo uses a hack to activate EDR display on iOS platform:
  
  - By setting up an invisible `AVPlayerLayer`, and plays short HDR video clip in the backgrond
  - inspired by https://github.com/kiding/wanna-see-a-whiter-white

Then we can use Metal with a Float Point pixel format to output EDR contents.

## Limitation

The "EDR trigger" hack basically   has the same effect with `metalLayer.wantsExtendedDynamicRangeContent = YES;`, 

But we still missing APIs like `-[NSScreen maximumExtendedDynamicRangeColorComponentValue]`, so it's very hard to apply appropriate tone-mapping within Metal rendering process.

This demo outputs the raw pixel values loaded by `CoreGraphics` without applying any tone-mapping, so the colors will clip at current EDR max value and may seems off.

## Credit

- Inspired by: 
  - https://kidi.ng/wanna-see-a-whiter-white/
- HDR Video (EDR Trigger): 
  - https://github.com/kiding/wanna-see-a-whiter-white
- HDR Image Resources: 
  - https://github.com/AcademySoftwareFoundation/openexr-images/tree/master/TestImages
- Some sample code from: 
  - https://developer.apple.com/wwdc21/10161
  - https://developer.apple.com/documentation/metal/using_a_render_pipeline_to_render_primitives?language=objc
