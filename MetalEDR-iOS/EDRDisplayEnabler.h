//
//  EDRDisplayEnabler.h
//  MetalEDR-iOS
//
//  Created by Wu Tian on 2021/6/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EDRDisplayEnabler : NSObject

+ (instancetype)sharedEnabler;

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign, readonly) BOOL lowPowerMode;

// active = enabled && !lowPowerMode
@property (nonatomic, assign, readonly) BOOL active;

@end

extern NSString * const EDRDisplayEnablerDidUpdateActiveStateNotification;
extern NSString * const EDRDisplayEnablerDidUpdateLowPowerModeStateNotification;

NS_ASSUME_NONNULL_END
