# Custom-Keys
A powerful and fully customizable iOS number pad that is compatible with dollar amounts and integers.

## Installation
To get started, copy the 4 files in the `src/` directory into your Xcode project.
1. `CKNumberPad.h`
2. `CKNumberPad.m`
3. `CKNumberPadConfiguration.h`
4. `CKNumberPadConfiguration.m`

## Getting Started

1. Next, move into your `ViewController.m` file and add `#import "CKNumberPad.h"` to the top of the file.
2. Go to your interface file and add a `UIView` and subclass it to `CKNumberPad`.
3. Link up this view to your code via an `IBOutlet` so you can reference it in your code.
4. In your `viewDidLoad:` method, initialize a `CKNumberPadConfiguration` object like so:

    ```objective-c
    CKNumberPadConfiguration *configuration = [[CKNumberPadConfiguration alloc] init];
    ```

5. From here, you can add any customizations you would like referencing your configuration object. Here are some common examples:

    ```objective-c 
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
    configuration.numberKeyFont = [UIFont systemFontOfSize:30.0f];
    configuration.customLeftKeyFont = [UIFont systemFontOfSize:19.0f];
    configuration.customRightKeyFont = [configuration.customLeftKeyFont copy];
    configuration.keySpacing = 7.0f;
    configuration.maxDollarAmount = [NSDecimalNumber decimalNumberWithString:@"10000000"];
    ```
    
6. Lastly, be sure to set your configuration on your numberpad:

    ```objective-c
    [self.numberPad setConfigurationForNumberPad:configuration];
    ```
    
7. Optionally, assign a delegate too:

    ```objective-c      
    self.numberPad.delegate = self;
    ```
    
