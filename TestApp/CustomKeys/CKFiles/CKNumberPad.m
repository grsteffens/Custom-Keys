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

#define LEFT_BUTTON_INDEX 9
#define RIGHT_BUTTON_INDEX 11

#define DEFAULT_FONT_SIZE 60.0f
#define CUSTOM_KEY_FONT_MULTIPLIER 0.24f
#define KEY_FONT_MULTIPLIER 0.37f

#pragma mark ImageKey

@interface ImageKey : UIView

// Variables
@property (nonatomic) UIImageView *imageView;

@end

@implementation ImageKey

@end

@class KeyLabel;

#pragma mark LabelKey

@interface LabelKey : UIView

// Variables
@property (nonatomic) KeyLabel *label;

@end

@implementation LabelKey

@end

#pragma mark KeyLabel

@interface KeyLabel : UILabel

// Variables
@property (nonatomic) NSString *fontName;

@end

@implementation KeyLabel

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIView *superView = self.superview;
    if (superView)
    {
        CGFloat size = (CGRectGetHeight(superView.frame) * KEY_FONT_MULTIPLIER);
        if ([self.text rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound ||
            self.text.length > 2)
        {
            size = (CGRectGetHeight(superView.frame) * CUSTOM_KEY_FONT_MULTIPLIER);
        }
        
        if (self.fontName.length > 0)
        {
            self.font = [UIFont fontWithName:self.fontName size:size];
        }
        else
        {
            self.font = [UIFont systemFontOfSize:size];
        }
    }
}

@end

#pragma mark CKNumberPad

@interface CKNumberPad ()

// Variables
@property (nonatomic) NSString *numberPadRawValue;
@property (nonatomic) UIView *leftButton;
@property (nonatomic) UIView *rightButton;

@property (nonatomic, readonly) NSNumberFormatter *currencyFormatter;
@property (nonatomic, readonly) NSNumberFormatter *percentageFormatter;

@property (nonatomic) UIStackView *masterStackView;

@property (nonatomic) NSMutableArray *labelKeys;
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
    
    self.labelKeys = [NSMutableArray new];
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
            
            if ((idx == LEFT_BUTTON_INDEX + 1) && self.configuration.doubleKeyBehavior != DoubleKeyBehaviorNone)
            {
                return;
            }
            
            if ([self keyUsesButtonAtIndex:idx])
            {
                LabelKey *key = [self createLabelKeyWithText:obj withTag:idx];
                [self.labelKeys addObject:key];
                [rowStackView addArrangedSubview:key];
            }
            else
            {
                UIImage *keyImage = [UIImage imageNamed:(idx == LEFT_BUTTON_INDEX ? self.configuration.leftButtonImageName : self.configuration.rightButtonImageName)];
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
                                                                               multiplier:CUSTOM_KEY_FONT_MULTIPLIER
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
        
        for (LabelKey *key in self.labelKeys)
        {
            NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:key.label
                                                                                attribute:NSLayoutAttributeHeight
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:key
                                                                                attribute:NSLayoutAttributeHeight
                                                                               multiplier:KEY_FONT_MULTIPLIER
                                                                                 constant:0.0f];
            NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:key.label
                                                                               attribute:NSLayoutAttributeWidth
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:key
                                                                               attribute:NSLayoutAttributeWidth
                                                                              multiplier:0.8f
                                                                                constant:0.0f];
            NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:key.label
                                                                       attribute:NSLayoutAttributeCenterX
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:key
                                                                       attribute:NSLayoutAttributeCenterX
                                                                      multiplier:1.0f
                                                                        constant:0.0f];
            NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:key.label
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
            UIView *firstView;
            UIView *secondView;
            
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
            
            if ((firstView && [firstView isKindOfClass:[UIView class]]) &&
                (secondView && [secondView isKindOfClass:[UIView class]]))
            {
                [self.masterStackView addConstraint:[self constraintWithItem:secondView
                                                                  masterItem:firstView
                                                                   attribute:NSLayoutAttributeWidth
                                                                    constant:0.0f]];
            }
        }
    }
}

- (BOOL)keyUsesButtonAtIndex:(NSInteger)index
{
    if ((index == LEFT_BUTTON_INDEX && self.configuration.leftButtonText.length == 0 && self.configuration.leftButtonImageName.length > 0) ||
        (index == RIGHT_BUTTON_INDEX && self.configuration.rightButtonText.length == 0 && self.configuration.rightButtonImageName.length > 0))
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

- (LabelKey*)createLabelKeyWithText:(NSString*)text withTag:(NSInteger)tag
{
    LabelKey *key = [LabelKey new];
    key.tag = tag;
    key.userInteractionEnabled = YES;
    key.layer.cornerRadius = self.configuration.keyCornerRadius;
    key.clipsToBounds = YES;
    key.layer.borderWidth = self.configuration.keyBorderWidth;
    key.layer.borderColor = self.configuration.keyBorderColor.CGColor;
    key.backgroundColor = self.configuration.keyBackgroundColor;
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                      action:@selector(longPressOnKey:)];
    longPressRecognizer.minimumPressDuration = 0.0f;
    [key addGestureRecognizer:longPressRecognizer];
    
    KeyLabel *label = [[KeyLabel alloc] init];
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = self.configuration.keyTextColor;
    label.adjustsFontSizeToFitWidth = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    if ((tag == LEFT_BUTTON_INDEX && self.configuration.customLeftKeyFontName) ||
        (tag == RIGHT_BUTTON_INDEX && self.configuration.customRightKeyFontName))
    {
        label.fontName = tag == LEFT_BUTTON_INDEX ?
        self.configuration.customLeftKeyFontName :
        self.configuration.customRightKeyFontName;
    }
    else if (self.configuration.numberKeyFontName)
    {
        label.fontName = self.configuration.numberKeyFontName;
    }
    
    [key addSubview:label];
    key.label = label;
    
    return key;
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
                                                                                                      action:@selector(longPressOnKey:)];
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

- (void)longPressOnKey:(UILongPressGestureRecognizer*)sender
{
    if ([sender.view isKindOfClass:[ImageKey class]])
    {
        ImageKey *key = (ImageKey*)sender.view;
        
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
    else if ([sender.view isKindOfClass:[LabelKey class]])
    {
        LabelKey *key = (LabelKey*)sender.view;
        
        if (sender.state == UIGestureRecognizerStateBegan)
        {
            [self playHaptic];
            
            key.backgroundColor = self.configuration.keyTappedBackgroundColor;
            key.label.textColor = self.configuration.keyTappedTextColor;
        }
        else if (sender.state == UIGestureRecognizerStateEnded)
        {
            [self handlePressOnKey:key];
            
            key.backgroundColor = self.configuration.keyBackgroundColor;
            key.label.textColor = self.configuration.keyTextColor;
        }
    }
}

- (void)handlePressOnKey:(UIView*)sender
{
    NSString *stringToAdd;
    
    if (sender.tag == LEFT_BUTTON_INDEX)
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
    else if (sender.tag == RIGHT_BUTTON_INDEX)
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
    
    if (sender.tag != LEFT_BUTTON_INDEX && sender.tag != RIGHT_BUTTON_INDEX)
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
