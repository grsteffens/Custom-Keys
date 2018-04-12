//
//  CKNumberPad.m
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

#import "CKNumberPad.h"

#define LeftButtonIndex 9
#define RightButtonIndex 11

#pragma mark ImageKey

@interface ImageKey : UIView

// Variables
@property (nonatomic) UIImageView *imageView;

@end

@implementation ImageKey

@end

#pragma mark CKNumberPad

@interface CKNumberPad ()

// Variables
@property (nonatomic) NSString *numberPadRawValue;
@property (nonatomic) UIButton *leftButton;
@property (nonatomic) UIButton *rightButton;

@property (nonatomic, readonly) NSNumberFormatter *currencyFormatter;
@property (nonatomic, readonly) NSNumberFormatter *percentageFormatter;

@property (nonatomic) UIStackView *masterStackView;

@property (nonatomic) NSMutableArray *imageKeys;

@end

@implementation CKNumberPad
{
    NSNumberFormatter *i_currencyFormatter;
    NSNumberFormatter *i_percentageFormatter;
    UIImpactFeedbackGenerator *hapticPlayer NS_AVAILABLE_IOS(10.0);
    NSArray<NSString*> *keys;
    CKNumberPadConfiguration *i_configuration;
    BOOL isFirstEntry;
}

- (void)setConfigurationForNumberPad:(CKNumberPadConfiguration *)config
{
    if (i_configuration)
        return;

    i_configuration = config;
    i_configuration.textField.userInteractionEnabled = NO;
    i_configuration.label.userInteractionEnabled = NO;

    _numberPadRawValue = @"";

    isFirstEntry = YES;

    [self setupKeyboard];
}

- (void)changeOutputControlDataType:(NumberPadOutputControlDataType)dataType
{
    i_configuration.outputControlDataType = dataType;
    [self clear];
}

- (void)changeMaxDollarAmount:(NSDecimalNumber *)amount
{
    i_configuration.maxDollarAmount = amount;
    [self clear];
}

- (void)changeMaxPercentageAmount:(NSDecimalNumber *)amount
{
    i_configuration.maxPercentageAmount = amount;
    [self clear];
}

#pragma mark UI setup

- (void)setupKeyboard
{
    CKNumberPadConfiguration *configuration = self.configuration;
    self.backgroundColor = configuration.backgroundColor;

    self.imageKeys = [NSMutableArray new];

    if (!self.masterStackView)
    {
        self.masterStackView = [[UIStackView alloc] init];
        self.masterStackView.alignment = UIStackViewAlignmentFill;
        self.masterStackView.distribution = UIStackViewDistributionFillEqually;
        self.masterStackView.spacing = self.configuration.keySpacing;
        self.masterStackView.axis = UILayoutConstraintAxisVertical;
        self.masterStackView.translatesAutoresizingMaskIntoConstraints = NO;

        __block UIStackView *rowStackView;
        __block NSInteger rowIndex = -1;
        NSArray<NSString*> *keypadButtonsText = [self keypadButtonsText];
        [keypadButtonsText enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx % 3 == 0)
            {
                rowIndex++;
                rowStackView = [self createRowStackViewForIndex:rowIndex];
            }

            if ((idx == LeftButtonIndex + 1) && self.configuration.doubleKeyBehavior != DoubleKeyBehaviorNone)
            {
                return;
            }

            if ([self keyUsesButtonAtIndex:idx])
            {
                UIButton *button = [self createKeyButtonWithText:obj withTag:idx];
                [rowStackView addArrangedSubview:button];
            }
            else
            {
                UIImage *keyImage = [UIImage imageNamed:(idx == LeftButtonIndex ? self.configuration.leftButtonImageName : self.configuration.rightButtonImageName)];
                ImageKey *key = [self createImageKeyWithImage:keyImage withTag:idx];
                [self.imageKeys addObject:key];
                [rowStackView addArrangedSubview:key];
            }

            [self.masterStackView addArrangedSubview:rowStackView];
        }];

        [self updateOutputControl];
        [self addSubview:self.masterStackView];

        [self addEdgesConstraintsToView:self.masterStackView insets:UIEdgeInsetsZero];

        for (ImageKey *key in self.imageKeys)
        {
            NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:key.imageView
                                                                                attribute:NSLayoutAttributeHeight
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:key
                                                                                attribute:NSLayoutAttributeHeight
                                                                               multiplier:0.25f
                                                                                 constant:0.0f];
            NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:key.imageView
                                                                               attribute:NSLayoutAttributeWidth
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:key
                                                                               attribute:NSLayoutAttributeWidth
                                                                              multiplier:0.8f
                                                                                constant:0.0f];
            NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:key.imageView
                                                                       attribute:NSLayoutAttributeCenterX
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:key
                                                                       attribute:NSLayoutAttributeCenterX
                                                                      multiplier:1.0f
                                                                        constant:0.0f];
            NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:key.imageView
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:key
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1.0f
                                                                        constant:0.0f];

            [key addConstraints:@[heightConstraint, widthConstraint, centerX, centerY]];
        }

        if (self.configuration.doubleKeyBehavior != DoubleKeyBehaviorNone)
        {
            UIButton *firstButton;
            id firstView;

            UIButton *secondButton;
            id secondView;

            UIStackView *fullSetStackView = ((UIStackView*)self.masterStackView.arrangedSubviews[self.masterStackView.arrangedSubviews.count-2]);
            if (fullSetStackView.arrangedSubviews.count > 0)
            {
                firstView = fullSetStackView.arrangedSubviews[0];
            }

            if (self.configuration.doubleKeyBehavior == DoubleKeyBehaviorBottomLeft)
            {
                UIStackView *semiSetStackView = ((UIStackView*)self.masterStackView.arrangedSubviews[self.masterStackView.arrangedSubviews.count-1]);

                if (semiSetStackView.arrangedSubviews.count > 1)
                {
                    secondView = semiSetStackView.arrangedSubviews[1];
                }
            }
            else
            {
                UIStackView *semiSetStackView = ((UIStackView*)self.masterStackView.arrangedSubviews[self.masterStackView.arrangedSubviews.count-1]);

                if (semiSetStackView.arrangedSubviews.count > 0)
                {
                    secondView = semiSetStackView.arrangedSubviews[0];
                }
            }

            if (firstView && [firstView isKindOfClass:[UIButton class]])
                firstButton = (UIButton*)firstView;

            if (secondView && [secondView isKindOfClass:[UIButton class]])
                secondButton = (UIButton*)secondView;

            [self.masterStackView addConstraint:[self constraintWithItem:secondButton
                                                              masterItem:firstButton
                                                               attribute:NSLayoutAttributeWidth
                                                                constant:0.0f]];
        }
    }
}

- (BOOL)keyUsesButtonAtIndex:(NSInteger)index
{
    if (index == LeftButtonIndex && self.configuration.leftButtonText.length == 0 && self.configuration.leftButtonImageName.length > 0)
    {
        return NO;
    }
    else if (index == RightButtonIndex && self.configuration.rightButtonText.length == 0 && self.configuration.rightButtonImageName.length > 0)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (UIStackView*)createRowStackViewForIndex:(NSInteger)rowIndex
{
    UIStackView *stackView = [UIStackView new];
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.spacing = self.configuration.keySpacing;
    stackView.axis = UILayoutConstraintAxisHorizontal;

    if (self.configuration.doubleKeyBehavior != DoubleKeyBehaviorNone && rowIndex == 3)
    {
        stackView.distribution = UIStackViewDistributionFillProportionally;
    }
    else
    {
        stackView.distribution = UIStackViewDistributionFillEqually;
    }

    return stackView;
}

- (UIButton*)createKeyButtonWithText:(NSString*)text withTag:(NSInteger)tag
{
    UIButton *button = [UIButton new];
    [button addTarget:self action:@selector(handlePressOnKey:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(playHaptic) forControlEvents:UIControlEventTouchDown];
    button.tag = tag;
    button.userInteractionEnabled = text != nil;
    button.layer.cornerRadius = self.configuration.keyCornerRadius;
    button.clipsToBounds = YES;
    button.layer.borderWidth = self.configuration.keyBorderWidth;
    button.layer.borderColor = self.configuration.keyBorderColor.CGColor;

    if (tag == LeftButtonIndex || tag == RightButtonIndex)
    {
        if ((tag == LeftButtonIndex &&
            self.configuration.leftButtonText.length == 0 &&
            self.configuration.leftButtonImageName.length > 0) ||
            (tag == RightButtonIndex &&
             self.configuration.rightButtonText.length == 0 &&
             self.configuration.rightButtonImageName.length > 0))
        {
            UIImage *image = [[UIImage imageNamed:text] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            CGFloat ratio = image.size.width / image.size.height;

            CGFloat newHeight = [self heightForKey] * 0.25;
            [button setImage:[self sizedImageWithImage:image
                                                height:newHeight
                                                 width:(newHeight * ratio)
                                                 color:self.configuration.keyTextColor]
                    forState:UIControlStateNormal];
            [button setImage:[self sizedImageWithImage:image
                                                height:newHeight
                                                 width:(newHeight * ratio)
                                                 color:self.configuration.keyTappedTextColor]
                    forState:UIControlStateHighlighted];
        }
        else
        {
            [button setTitle:text forState:UIControlStateNormal];
        }
    }
    else
    {
        [button setTitle:text forState:UIControlStateNormal];
    }

    if ((tag == LeftButtonIndex && self.configuration.customLeftKeyFont) ||
        (tag == RightButtonIndex && self.configuration.customRightKeyFont))
    {
        button.titleLabel.font = tag == LeftButtonIndex ? self.configuration.customLeftKeyFont : self.configuration.customRightKeyFont;
    }
    else if (self.configuration.numberKeyFont)
    {
        button.titleLabel.font = self.configuration.numberKeyFont;
    }

    button.titleLabel.adjustsFontSizeToFitWidth = YES;

    [button setTitleColor:self.configuration.keyTextColor forState:UIControlStateNormal];
    [button setBackgroundImage:[self backgroundImageForColor:self.configuration.keyBackgroundColor]
                      forState:UIControlStateNormal];

    [button setTitleColor:self.configuration.keyTappedTextColor forState:UIControlStateHighlighted];
    [button setBackgroundImage:[self backgroundImageForColor:self.configuration.keyTappedBackgroundColor]
                      forState:UIControlStateHighlighted];

    return button;
}

- (ImageKey*)createImageKeyWithImage:(UIImage*)image withTag:(NSInteger)tag
{
    ImageKey *key = [ImageKey new];
    key.tag = tag;
    key.userInteractionEnabled = image != nil;
    key.layer.cornerRadius = self.configuration.keyCornerRadius;
    key.clipsToBounds = YES;
    key.layer.borderWidth = self.configuration.keyBorderWidth;
    key.layer.borderColor = self.configuration.keyBorderColor.CGColor;
    key.backgroundColor = self.configuration.keyBackgroundColor;

    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                      action:@selector(longPressOnImageKey:)];
    longPressRecognizer.minimumPressDuration = 0.0f;
    [key addGestureRecognizer:longPressRecognizer];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tintColor = self.configuration.keyTextColor;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;

    [key addSubview:imageView];
    key.imageView = imageView;

    return key;
}

- (NSArray<NSString*>*)keypadButtonsText
{
    if (!keys)
    {
        NSString *leftButtonValue = self.configuration.leftButtonText.length > 0 ? self.configuration.leftButtonText : self.configuration.leftButtonImageName;
        NSString *rightButtonValue = self.configuration.rightButtonText.length > 0 ? self.configuration.rightButtonText : self.configuration.rightButtonImageName;

        NSArray<NSString*> *baseKeys = @[@"1",
                                         @"2",
                                         @"3",
                                         @"4",
                                         @"5",
                                         @"6",
                                         @"7",
                                         @"8",
                                         @"9",
                                         leftButtonValue,
                                         @"0",
                                         rightButtonValue];

        keys = baseKeys;
    }

    return keys;
}

#pragma mark Helper methods

- (UIImage*)backgroundImageForColor:(UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0f, 1.0f), NO, 0);
    [color setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f)] fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (void)playHaptic
{
    if (!self.configuration.playHapticOnKeyPress)
        return;

    // Play haptic for touch on key
    if (@available(iOS 10.0, *))
    {
        if (!hapticPlayer)
            hapticPlayer = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];

        [hapticPlayer impactOccurred];
    }
}

- (BOOL)checkInput:(NSString*)valueToAdd
{
    if (self.configuration.outputControlDataType == NumberPadOutputControlDataTypeInteger)
    {
        NSInteger newInteger = [[self.numberPadRawValue stringByAppendingString:valueToAdd] integerValue];

        return !(newInteger >= NSIntegerMax);
    }

    return YES;
}

- (BOOL)leftButtonUsesImage
{
    return self.configuration.leftButtonText == nil && self.configuration.leftButtonImageName.length > 0;
}

- (BOOL)rightButtonUsesImage
{
    return self.configuration.rightButtonText == nil && self.configuration.rightButtonImageName.length > 0;
}

- (CGFloat)heightForKey
{
    NSInteger rowCount = ([self keypadButtonsText].count / 3);

    CGFloat stackViewTotalHeight = CGRectGetHeight(self.frame);
    stackViewTotalHeight -= (rowCount - 1) * self.masterStackView.spacing;

    return stackViewTotalHeight / rowCount;
}

- (void)addEdgesConstraintsToView:(UIView *)view insets:(UIEdgeInsets)insets
{
    [self addConstraint:[self constraintWithItem:view
                                      masterItem:self
                                       attribute:NSLayoutAttributeTop
                                        constant:insets.top]];
    [self addConstraint:[self constraintWithItem:view
                                      masterItem:self
                                       attribute:NSLayoutAttributeLeft
                                        constant:insets.left]];
    [self addConstraint:[self constraintWithItem:view
                                      masterItem:self
                                       attribute:NSLayoutAttributeBottom
                                        constant:-insets.bottom]];
    [self addConstraint:[self constraintWithItem:view
                                      masterItem:self
                                       attribute:NSLayoutAttributeRight
                                        constant:-insets.right]];
}

- (NSLayoutConstraint*)constraintWithItem:(UIView*)viewOne masterItem:(UIView*)viewTwo attribute:(NSLayoutAttribute)attribute constant:(CGFloat)constant
{
    return [NSLayoutConstraint constraintWithItem:viewOne
                                        attribute:attribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:viewTwo
                                        attribute:attribute
                                       multiplier:1.0f
                                         constant:constant];
}

- (UIImage*)sizedImageWithImage:(UIImage*)image height:(CGFloat)height width:(CGFloat)width color:(UIColor*)color
{
    UIImage *newImage = color == nil ? image : [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 0.0);
    if (color) [color set];
    [newImage drawInRect:CGRectMake(0, 0, width, height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark Setters

- (void)setNumberPadRawValue:(NSString *)numberPadRawValue
{
    [self.configuration checkMaxValue:&numberPadRawValue];
    _numberPadRawValue = numberPadRawValue;

    isFirstEntry = NO;

    [self updateOutputControl];

    if ([self.delegate respondsToSelector:@selector(numberPad:valueDidChange:)])
        [self.delegate numberPad:self valueDidChange:self.rawValue];
}

#pragma mark Getters

- (NSString *)rawValue
{
    return self.numberPadRawValue;
}

- (NSDecimalNumber *)decimalValue
{
    return [self.configuration decimalValueOfString:self.numberPadRawValue];
}

- (NSInteger)integerValue
{
    return [self.numberPadRawValue integerValue];
}

- (CKNumberPadConfiguration *)configuration
{
    return i_configuration;
}

- (NSNumberFormatter *)currencyFormatter
{
    if (self.configuration.numberFormatter)
        return self.configuration.numberFormatter;

    if (!i_currencyFormatter)
    {
        i_currencyFormatter = [NSNumberFormatter new];
        i_currencyFormatter.locale = [NSLocale currentLocale];
        i_currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
        i_currencyFormatter.usesGroupingSeparator = YES;
        [i_currencyFormatter setMinimumFractionDigits:self.configuration.numberOfCurrencyDecimalPlaces];

        if (self.configuration.hideNumericalSymbol)
        {
            i_currencyFormatter.currencySymbol = @"";
        }
    }

    return i_currencyFormatter;
}

- (NSNumberFormatter *)percentageFormatter
{
    if (self.configuration.numberFormatter)
        return self.configuration.numberFormatter;

    if (!i_percentageFormatter)
    {
        i_percentageFormatter = [NSNumberFormatter new];
        i_percentageFormatter.locale = [NSLocale currentLocale];
        i_percentageFormatter.numberStyle = NSNumberFormatterPercentStyle;
        i_percentageFormatter.usesGroupingSeparator = NO;
        [i_percentageFormatter setMinimumFractionDigits:self.configuration.numberOfPercentageDecimalPlaces];
        [i_percentageFormatter setMaximumFractionDigits:self.configuration.numberOfPercentageDecimalPlaces];

        if (self.configuration.hideNumericalSymbol)
        {
            i_percentageFormatter.percentSymbol = @"";
        }
    }

    return i_percentageFormatter;
}

#pragma mark Actions

- (void)overrideDecimalValue:(NSDecimalNumber*)decimalValue
{
    NSString *stringOverride = [[decimalValue decimalNumberByMultiplyingBy:[[NSDecimalNumber decimalNumberWithMantissa:10 exponent:0 isNegative:NO]
                                                                            decimalNumberByRaisingToPower:[self.configuration numberOfDecimalPlaces]]] stringValue];
    self.numberPadRawValue = stringOverride;
    isFirstEntry = YES;
}

- (void)overrideIntegerValue:(NSInteger)integerValue
{
    self.numberPadRawValue = [[NSNumber numberWithInteger:integerValue] stringValue];
    isFirstEntry = YES;
}

- (void)longPressOnImageKey:(UILongPressGestureRecognizer*)sender
{
    ImageKey *key = nil;
    if ([sender.view isKindOfClass:[ImageKey class]])
    {
        key = (ImageKey*)sender.view;
    }

    if (!key) return;

    if (sender.state == UIGestureRecognizerStateBegan)
    {
        [self playHaptic];

        key.backgroundColor = self.configuration.keyTappedBackgroundColor;
        key.imageView.tintColor = self.configuration.keyTappedTextColor;
    }
    else if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self handlePressOnKey:key];

        key.backgroundColor = self.configuration.keyBackgroundColor;
        key.imageView.tintColor = self.configuration.keyTextColor;
    }
}

- (void)handlePressOnKey:(UIView*)sender
{
    NSString *stringToAdd;

    if (sender.tag == LeftButtonIndex)
    {
        switch (self.configuration.leftButtonAction)
        {
            case CustomKeyActionBackspace:
                [self backspaceOnRawValue];
                break;

            case CustomKeyActionSingleZero:
                stringToAdd = @"0";
                break;

            case CustomKeyActionDoubleZero:
                stringToAdd = @"00";
                break;

            case CustomKeyActionReportToDelegate:
                if ([self.delegate respondsToSelector:@selector(numberPadDidTapLeftButton)])
                    [self.delegate numberPadDidTapLeftButton];
                break;

            case CustomKeyActionClear:
                self.numberPadRawValue = @"";
                [self updateOutputControl];

                if ([self.delegate respondsToSelector:@selector(numberPadDidClear)])
                    [self.delegate numberPadDidClear];
                break;
        }
    }
    else if (sender.tag == RightButtonIndex)
    {
        switch (self.configuration.rightButtonAction)
        {
            case CustomKeyActionBackspace:
                [self backspaceOnRawValue];
                break;

            case CustomKeyActionSingleZero:
                stringToAdd = @"0";
                break;

            case CustomKeyActionDoubleZero:
                stringToAdd = @"00";
                break;

            case CustomKeyActionReportToDelegate:
                if ([self.delegate respondsToSelector:@selector(numberPadDidTapRightButton)])
                    [self.delegate numberPadDidTapRightButton];
                break;

            case CustomKeyActionClear:
                self.numberPadRawValue = @"";
                [self updateOutputControl];

                if ([self.delegate respondsToSelector:@selector(numberPadDidClear)])
                    [self.delegate numberPadDidClear];
                break;
        }
    }
    else
    {
        stringToAdd = [self keypadButtonsText][sender.tag];
    }

    if (stringToAdd && [self checkInput:stringToAdd])
    {
        if (isFirstEntry)
        {
            self.numberPadRawValue = stringToAdd;
        }
        else
        {
            self.numberPadRawValue = [self.numberPadRawValue stringByAppendingString:stringToAdd];
        }
    }

    if (sender.tag != LeftButtonIndex && sender.tag != RightButtonIndex)
    {
        if ([self.delegate respondsToSelector:@selector(numberPadDidTapIntegerKey)])
            [self.delegate numberPadDidTapIntegerKey];
    }
}

- (void)backspaceOnRawValue
{
    if ([self.numberPadRawValue length] > 0) {
        self.numberPadRawValue = [self.numberPadRawValue substringToIndex:self.numberPadRawValue.length - 1];

        if ([self.delegate respondsToSelector:@selector(numberPadDidDeleteSingleValue)])
            [self.delegate numberPadDidDeleteSingleValue];
    }
}

- (void)updateOutputControl
{
    if (!self.configuration.textField && !self.configuration.label)
        return;

    NSString *textValue;

    CKNumberPadConfiguration *config = self.configuration;
    if (config.outputControlDataType == NumberPadOutputControlDataTypeInteger)
    {
        textValue = [NSString stringWithFormat:@"%lu", (unsigned long)self.integerValue];
    }
    else
    {
        NSDecimalNumber *value = self.decimalValue;

        if (config.outputControlDataType == NumberPadOutputControlDataTypeMoney)
        {
            textValue = [self.currencyFormatter stringFromNumber:value];
        }
        else if (config.outputControlDataType == NumberPadOutputControlDataTypePercentage)
        {
            NSDecimalNumber *multiplier = [[NSDecimalNumber decimalNumberWithString:@"10"]
                                           decimalNumberByRaisingToPower:[self.configuration numberOfDecimalPlaces]];
            value = [value decimalNumberByDividingBy:multiplier];

            if ([self.configuration numberOfDecimalPlaces] == 0)
                value = [value decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];

            textValue = [self.percentageFormatter stringFromNumber:value];
        }
    }

    if (self.configuration.textField)
    {
        self.configuration.textField.text = textValue;
    }

    if (self.configuration.label)
    {
        self.configuration.label.text = textValue;
    }
}

- (void)clear
{
    self.numberPadRawValue = @"";
    isFirstEntry = YES;
    [self updateOutputControl];

    if ([self.delegate respondsToSelector:@selector(numberPadDidClear)])
        [self.delegate numberPadDidClear];
}

- (void)backspace
{
    [self backspaceOnRawValue];
}

@end
