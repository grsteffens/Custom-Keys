//
//  CKNumberPad.h
//
//  MIT License
//
//  Copyright (c) 2018 Garrett Steffens
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <UIKit/UIKit.h>

#import "CKNumberPadConfiguration.h"

@class CKNumberPad;

#pragma mark CKNumberPadDelegate methods

@protocol CKNumberPadDelegate <NSObject>

@optional
/**
 An optional delegate method that is called when the number pad's value changes
 
 @param numberPad The number pad instance
 @param newRawValue The new raw NSString value (after change)
 */
- (void)numberPad:(CKNumberPad*)numberPad valueDidChange:(NSString*)newRawValue;

/**
 An optional delegate method that is called when the number pad is cleared
 */
- (void)numberPadDidClear;

/**
 An optional delegate method that is called when a key within the 0-9 range is tapped
 */
- (void)numberPadDidTapIntegerKey;

/**
 An optional delegate method that is called when the bottom left key is tapped
 */
- (void)numberPadDidTapLeftButton;

/**
 An optional delegate method that is called when the bottom right key is tapped
 */
- (void)numberPadDidTapRightButton;

/**
 An optional delegate method that is called when the number pad backspaces one value
 */
- (void)numberPadDidDeleteSingleValue;

@end

#pragma mark CKNumberPad methods

@interface CKNumberPad : UIView

/**
 The delegate for the number pad, optional
 */
@property (weak, nonatomic) id<CKNumberPadDelegate> delegate;

/**
 A readonly getter that returns the decimal value of the number pad formatted as specified in the CKNumberPadConfiguration
 */
@property (readonly) NSDecimalNumber *decimalValue;

/**
 A readonly getter that returns the integer value of the number pad formatted as specified in the CKNumberPadConfiguration
 */
@property (readonly) NSInteger integerValue;

/**
 The current configuration for the number pad
 */
@property (readonly) CKNumberPadConfiguration *configuration;

/**
 Allows you to override the current value of the number pad
 
 @param integerValue NSInteger override value
 */
- (void)overrideIntegerValue:(NSInteger)integerValue;

/**
 Allows you to override the current value of the number pad
 
 @param decimalValue NSDecimalNumber override value
 */
- (void)overrideDecimalValue:(NSDecimalNumber*)decimalValue;

/**
 Sets the configuration for the number pad that includes formatting and UI settings
 
 @param config instance of CKNumberPadConfiguration
 */
- (void)setConfigurationForNumberPad:(CKNumberPadConfiguration*)config;

/**
 Allows you to override the outputControlDataType on the current configuration
 
 @param dataType The control data type
 */
- (void)changeOutputControlDataType:(NumberPadOutputControlDataType)dataType;

/**
 Allows you to change the max dollar (decimal) amount for the number pad
 
 @param amount Max decimal amount
 */
- (void)changeMaxDollarAmount:(NSDecimalNumber*)amount;

/**
 Allows you to change the max percent amount for the number pad
 
 @param amount Max percent amount
 */
- (void)changeMaxPercentageAmount:(NSDecimalNumber*)amount;

/**
 Backspaces one character
 */
- (void)backspace;

/**
 Clears the number pad
 */
- (void)clear;

@end
