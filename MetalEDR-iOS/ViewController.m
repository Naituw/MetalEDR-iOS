//
//  ViewController.m
//  MetalEDR-iOS
//
//  Created by Wu Tian on 2021/6/13.
//

#import "ViewController.h"
#import "EDRImageView.h"
#import "EDRDisplayEnabler.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *uiImageView;
@property (weak, nonatomic) IBOutlet EDRImageView *edrImageView;
@property (weak, nonatomic) IBOutlet UISwitch *edrSwitch;
@property (weak, nonatomic) IBOutlet UILabel *lowPowerModeLabel;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    // images from https://github.com/AcademySoftwareFoundation/openexr-images/tree/master/TestImages
    
    UIImage * image = [UIImage imageNamed:@"GrayRampsHorizontal.exr"];
//    UIImage * image = [UIImage imageNamed:@"Balls.exr"];
//    UIImage * image = [UIImage imageNamed:@"RgbRampsDiagonal.exr"];
//    UIImage * image = [UIImage imageNamed:@"BrightRings.exr"];

    _uiImageView.image = image;
    _edrImageView.image = image;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lowPowerModeUpdate:) name:EDRDisplayEnablerDidUpdateLowPowerModeStateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(edrActiveUpdate:) name:EDRDisplayEnablerDidUpdateActiveStateNotification object:nil];
    [self _updateControlsState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [EDRDisplayEnabler sharedEnabler].enabled = YES;
}

- (void)_updateControlsState
{
    BOOL lowPowerMode = [EDRDisplayEnabler sharedEnabler].lowPowerMode;
    
    _lowPowerModeLabel.hidden = !lowPowerMode;
    _edrSwitch.enabled = !lowPowerMode;
    _edrSwitch.on = [EDRDisplayEnabler sharedEnabler].active;
}

- (void)lowPowerModeUpdate:(NSNotification *)notification
{
    [self _updateControlsState];
}

- (void)edrActiveUpdate:(NSNotification *)notification
{
    [self _updateControlsState];
}

- (IBAction)edrSwitchAction:(id)sender
{
    [EDRDisplayEnabler sharedEnabler].enabled = _edrSwitch.on;
    
    [self _updateControlsState];
}

@end
