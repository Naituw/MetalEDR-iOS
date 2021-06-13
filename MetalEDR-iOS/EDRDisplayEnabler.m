//
//  EDRDisplayEnabler.m
//  MetalEDR-iOS
//
//  Created by Wu Tian on 2021/6/13.
//

#import "EDRDisplayEnabler.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface EDRDisplayEnabler ()
{
    struct {
        unsigned int initializing: 1;
    } _flags;
}

@property (nonatomic, assign) BOOL lowPowerMode;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, strong) AVPlayerLayer * playerLayer;

@end

@implementation EDRDisplayEnabler

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedEnabler
{
    static EDRDisplayEnabler * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [EDRDisplayEnabler new];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerStateUpdateNotification:) name:NSProcessInfoPowerStateDidChangeNotification object:nil];
        _flags.initializing = YES;
        [self _updateStates];
        _flags.initializing = NO;
    }
    return self;
}

- (void)_updateActiveState
{
    self.active = _enabled && !_lowPowerMode;
}

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        _enabled = enabled;
        
        [self _updateActiveState];
    }
}

- (void)setLowPowerMode:(BOOL)lowPowerMode
{
    if (_lowPowerMode != lowPowerMode) {
        _lowPowerMode = lowPowerMode;
        
        if (!_flags.initializing) {
            [[NSNotificationCenter defaultCenter] postNotificationName:EDRDisplayEnablerDidUpdateLowPowerModeStateNotification object:self];
        }
        
        [self _updateActiveState];
    }
}

- (void)setActive:(BOOL)active
{
    if (_active != active) {
        _active = active;
        
        if (active) {
            if (!_playerLayer) {
                NSURL * url = [[NSBundle mainBundle] URLForResource:@"hdr" withExtension:@"mp4"];
                _playerLayer = [AVPlayerLayer layer];
                _playerLayer.player = [AVPlayer playerWithURL:url];
                _playerLayer.frame = CGRectMake(0, 0, 0.001, 0.001);
                _playerLayer.opacity = 0.01;
                
                UIWindow * window = [UIApplication sharedApplication].windows.firstObject;
                [window.layer addSublayer:_playerLayer];
            }
        } else {
            if (_playerLayer) {
                [_playerLayer removeFromSuperlayer];
                _playerLayer = nil;
            }
        }
        
        if (!_flags.initializing) {
            [[NSNotificationCenter defaultCenter] postNotificationName:EDRDisplayEnablerDidUpdateActiveStateNotification object:self];
        }
    }
}

- (void)_updateStates
{
    self.lowPowerMode = [NSProcessInfo processInfo].lowPowerModeEnabled;
}

- (void)powerStateUpdateNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updateStates];
    });
}

@end

NSString * const EDRDisplayEnablerDidUpdateActiveStateNotification = @"EDRDisplayEnablerDidUpdateActiveStateNotification";
NSString * const EDRDisplayEnablerDidUpdateLowPowerModeStateNotification = @"EDRDisplayEnablerDidUpdateLowPowerModeStateNotification";
