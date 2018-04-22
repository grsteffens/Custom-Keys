//
//  ViewController.m
//  CustomKeys
//
//  Created by Garrett Steffens on 4/11/18.
//  Copyright © 2018 Garrett Steffens. All rights reserved.
//

#import "ViewController.h"

#import "CKNumberPad.h"

@interface ViewController () <CKNumberPadDelegate>

@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UITextField *outputTextField;
@property (weak, nonatomic) IBOutlet CKNumberPad *numberPad;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup the number pad configuration
    CKNumberPadConfiguration *configuration = [[CKNumberPadConfiguration alloc] init];
    configuration.label = self.outputLabel;
    configuration.textField = self.outputTextField;
    configuration.outputControlDataType = NumberPadOutputControlDataTypeMoney;
    configuration.keyBackgroundColor = [UIColor whiteColor];
    configuration.rightButtonText = @"BACK";
    configuration.rightButtonAction = CustomKeyActionBackspace;
    configuration.leftButtonText = @"CLEAR";
    configuration.leftButtonAction = CustomKeyActionClear;
    configuration.keyTappedTextColor = [UIColor whiteColor];
    configuration.keyTappedBackgroundColor = [UIColor orangeColor];
    configuration.keyCornerRadius = 1.5f;
    configuration.keySpacing = 7.0f;
    configuration.maxDollarAmount = [NSDecimalNumber decimalNumberWithString:@"10000000"];
    
    [self.numberPad setConfigurationForNumberPad:configuration];
    self.numberPad.delegate = self;
}

#pragma mark CKNumberPadDelegate

- (void)numberPad:(CKNumberPad *)numberPad valueDidChange:(NSString *)newRawValue
{
    NSLog(@"Number pad new value => %@", newRawValue);
}

@end
