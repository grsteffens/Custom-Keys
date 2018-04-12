//
//  CKNumberPadConfiguration.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CustomKeyAction)
{
    CustomKeyActionReportToDelegate, // Fires its respective delegate method
    CustomKeyActionBackspace, // Deletes one character from end of string
    CustomKeyActionSingleZero, // Inserts one zero
    CustomKeyActionDoubleZero, // Inserts two zeros
    CustomKeyActionClear // Clears the number pad and sets value to empty
};

typedef NS_ENUM(NSInteger, NumberPadOutputControlDataType)
{
    NumberPadOutputControlDataTypeInteger,
    NumberPadOutputControlDataTypeMoney,
    NumberPadOutputControlDataTypePercentage
};

typedef NS_ENUM(NSInteger, DoubleKeyBehavior)
{
    DoubleKeyBehaviorNone,
    DoubleKeyBehaviorBottomLeft,
    DoubleKeyBehaviorBottomRight
};

@interface CKNumberPadConfiguration : NSObject

/**
 This method is a utility to enable the use of a hex string to generate a UIColor

 @param hex Can be in the form of #000000 or 000000
 */
- (UIColor*)colorForHexString:(NSString*)hex;

/**
 This method makes sure the value entered does not exceed the max value for the selected data type

 @param valueEntered The pointer of the string entered into the number pad
 @return Whether or not the max value was reached and prevented overflow
 */
- (BOOL)checkMaxValue:(NSString**)valueEntered;

/**
 Calculate decimal value of string based on configuration

 @return NSDecimalNumber Decimal Number value
 @param string The string to convert
 */
- (NSDecimalNumber*)decimalValueOfString:(NSString*)string;

/**
 Get number of decimal places for selected data type

 @return NSInteger Number of decimal places for selected data type
 */
- (NSInteger)numberOfDecimalPlaces;

/**
 The text field you want to link to the number pad
 */
@property (nonatomic) UITextField *textField;

/**
 The label you want to link to the number pad
 */
@property (nonatomic) UILabel *label;

/**
 The mask applied to the value injected into the output control
 */
@property (nonatomic) NumberPadOutputControlDataType outputControlDataType;

/**
 How many decimal places the value will maintain if using currency

 Note-- this will be ignored if textFieldDataType == NumberPadTextFieldDataTypeInteger for obvious reasons
 */
@property (nonatomic) NSInteger numberOfCurrencyDecimalPlaces;

/**
 How many decimal places the value will maintain if using percentage

 Note-- this will be ignored if textFieldDataType == NumberPadTextFieldDataTypeInteger for obvious reasons
 */
@property (nonatomic) NSInteger numberOfPercentageDecimalPlaces;

/**
 The max dollar amount for the number pad

 Default is 100000
 */
@property (nonatomic) NSDecimalNumber *maxDollarAmount;

/**
 The max percentage amount for the number pad

 Default is 100
 */
@property (nonatomic) NSDecimalNumber *maxPercentageAmount;

/**
 The maximum integer length (digit count)
*/
@property (nonatomic) NSInteger maxIntegerDigits;

/**
 The bottom left button text
 */
@property (nonatomic) NSString *leftButtonText;

/**
 The bottom left button image name
 */
@property (nonatomic) NSString *leftButtonImageName;

/**
 The action to occur when the custom bottom left button is tapped
 */
@property (nonatomic) CustomKeyAction leftButtonAction;

/**
 The bottom right button text
 */
@property (nonatomic) NSString *rightButtonText;

/**
 The bottom right button image name
 */
@property (nonatomic) NSString *rightButtonImageName;

/**
 The action to occur when the custom bottom right button is tapped
 */
@property (nonatomic) CustomKeyAction rightButtonAction;

/**
 The font for the number keys
 */
@property (nonatomic) UIFont *numberKeyFont;

/**
 The font for the left custom key
 */
@property (nonatomic) UIFont *customLeftKeyFont;

/**
 The font for the right custom key
 */
@property (nonatomic) UIFont *customRightKeyFont;

/**
 The color of the keys' text - default is [UIColor blackColor]
 */
@property (nonatomic) UIColor *keyTextColor;

/**
 The color of the keys' background - default is [UIColor clearColor]
 */
@property (nonatomic) UIColor *keyBackgroundColor;

/**
 The text color that is briefly shown to highlight the key when tapped - default is self.keyTextColor
 */
@property (nonatomic) UIColor *keyTappedTextColor;

/**
 The color that is briefly shown to highlight the key when tapped - default is [UIColor clearColor]
 */
@property (nonatomic) UIColor *keyTappedBackgroundColor;

/**
 The border width for the keys
 */
@property (nonatomic) CGFloat keyBorderWidth;

/**
 The border color for the keys
 */
@property (nonatomic) UIColor *keyBorderColor;

/**
 The corner radius for the keys
 */
@property (nonatomic) CGFloat keyCornerRadius;

/**
 Whether or not the bottom left 2/bottom right 2 keys are combined
 */
@property (nonatomic) DoubleKeyBehavior doubleKeyBehavior;

/**
 The background color of the keyboard - default is [UIColor clearColor]
 */
@property (nonatomic) UIColor *backgroundColor;

/**
 Flag determing whether or not to play a haptic (on compatible devices) when pressing a key
 */
@property (nonatomic) BOOL playHapticOnKeyPress;

/**
 The number formatter you would like to use to format your input
 */
@property (nonatomic) NSNumberFormatter *numberFormatter;

/**
 Hide the numerical symbol ($, %, etc.)
 */
@property (nonatomic) BOOL hideNumericalSymbol;

/**
 Spacing between the keys

 Default is 5.0f
 */
@property (nonatomic) CGFloat keySpacing;

@end
