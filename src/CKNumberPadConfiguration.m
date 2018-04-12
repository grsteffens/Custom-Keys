//
//  CKNumberPadConfiguration.m
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

#import "CKNumberPadConfiguration.h"

@implementation CKNumberPadConfiguration
{
    NSDecimalNumber *_maxAmount;
    NSString *_overrideStringValue;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _leftButtonText = @"";
        _leftButtonImageName = @"";
        _rightButtonText = @"";
        _rightButtonImageName = @"";
        _keyTextColor = [UIColor blackColor];
        _keyBackgroundColor = [UIColor clearColor];
        _keyTappedTextColor = [_keyTextColor copy];
        _keyTappedBackgroundColor = [UIColor clearColor];
        _backgroundColor = [UIColor clearColor];
        _keySpacing = 5.0f;
        _keyBorderColor = [UIColor clearColor];
        _maxDollarAmount = [NSDecimalNumber decimalNumberWithString:@"100000"];
        _maxPercentageAmount = [NSDecimalNumber decimalNumberWithString:@"100"];
        _maxIntegerDigits = -1;

        [self setInternalValues];
    }

    return self;
}

- (void)setInternalValues
{
    _maxAmount = _outputControlDataType == NumberPadOutputControlDataTypePercentage ?
                 _maxPercentageAmount :
                 _maxDollarAmount;
}

#pragma mark Setter methods

- (void)setMaxDollarAmount:(NSDecimalNumber *)maxDollarAmount
{
    _maxDollarAmount = maxDollarAmount;

    [self setInternalValues];
}

- (void)setMaxPercentageAmount:(NSDecimalNumber *)maxPercentageAmount
{
    _maxPercentageAmount = maxPercentageAmount;

    [self setInternalValues];
}

- (void)setOutputControlDataType:(NumberPadOutputControlDataType)outputControlDataType
{
    _outputControlDataType = outputControlDataType;

    if (outputControlDataType == NumberPadOutputControlDataTypeMoney)
    {
        self.numberOfCurrencyDecimalPlaces = 2;
    }

    [self setInternalValues];
}

#pragma mark Utility methods

- (UIColor*)colorForHexString:(NSString*)hex
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];

    if ([hex containsString:@"#"])
    {
        [scanner setScanLocation:1];
    }
    [scanner scanHexInt:&rgbValue];

    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0
                           green:((rgbValue & 0xFF00) >> 8)/255.0
                            blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (BOOL)checkMaxValue:(NSString *__autoreleasing *)valueEntered
{
    if (self.outputControlDataType == NumberPadOutputControlDataTypePercentage ||
        self.outputControlDataType == NumberPadOutputControlDataTypeMoney)
    {
        NSDecimalNumber *decimalValue = [self decimalValueOfString:*valueEntered];

        if ([decimalValue compare:_maxAmount] == NSOrderedDescending)
        {
            *valueEntered = [[_maxAmount decimalNumberByMultiplyingByPowerOf10:[self numberOfDecimalPlaces]] stringValue];
            return YES;
        }
    }
    else if (self.outputControlDataType == NumberPadOutputControlDataTypeInteger)
    {
        if (self.maxIntegerDigits > -1)
        {
            NSString *value = (NSString*)*valueEntered;

            if (value.length > self.maxIntegerDigits)
            {
                *valueEntered = [value substringToIndex:self.maxIntegerDigits];
                return YES;
            }
        }
    }

    return NO;
}

- (NSDecimalNumber*)decimalValueOfString:(NSString*)string
{
    @try
    {
        NSDecimalNumber *decimalValue = [NSDecimalNumber decimalNumberWithString:string];

        if ([decimalValue isEqualToNumber:[NSDecimalNumber notANumber]])
        {
            return [NSDecimalNumber zero];
        }
        else
        {
            if ([self numberOfDecimalPlaces] > 0)
            {
                decimalValue = [decimalValue decimalNumberByMultiplyingByPowerOf10:-([self numberOfDecimalPlaces])];
            }

            return decimalValue;
        }
    }
    @catch (NSException *exception)
    {
        return [NSDecimalNumber zero];
    }
}

- (NSInteger)numberOfDecimalPlaces
{
    NSInteger places = 0;

    if (self.outputControlDataType == NumberPadOutputControlDataTypeMoney)
    {
        places = self.numberOfCurrencyDecimalPlaces;
    }
    else if (self.outputControlDataType == NumberPadOutputControlDataTypePercentage)
    {
        places = self.numberOfPercentageDecimalPlaces;
    }

    return places;
}

@end
