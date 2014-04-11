//
//  OCMaskedTextField.m
//  OCFieldMask
//
//  Created by Ömer Cora on 09/04/14.
//  Copyright (c) 2014 MakaraKukara. All rights reserved.
//

/*
 
 Copyright 2014 Omer Cora
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "OCMaskedTextFieldView.h"

#define MASK_CHAR_NUMERIC      @"#"
#define MASK_CHAR_ALPHANUMERIC @"&"
#define MASK_CHAR_LETTER       @"?"

@implementation OCMaskedTextFieldView
{
    //mask
    NSString *format;
    
    //masking character for blank parts;
    NSString *numericBlank;
    NSString *alphaNumericBlank;
    NSString *letterBlank;
    
    //user input is stored here
    NSString *inputText;
    
    //subViews
    UITextField *maskedTextField;
    UIButton *button;
}

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame andMask:@"" showMask:NO];
}

- (id)initWithFrame: (CGRect)frame andMask: (NSString*)maskString
{
    return [self initWithFrame:frame andMask:maskString showMask:NO];
}

- (id)initWithFrame:(CGRect)frame andMask: (NSString*)maskString showMask:(BOOL)showMask
{
    if (self = [super initWithFrame:frame])
    {
        format    = maskString;
        [self configureViewShowMask:showMask];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self configureViewShowMask:NO];
    }
    return self;
}

-(void)configureViewShowMask:(BOOL)showMask
{
    inputText = @"";
    
    numericBlank      = @"_";
    alphaNumericBlank = @"_";
    letterBlank       = @"_";
    
    [self configureTextField];
    [self configureButton];
    
    if (showMask)
    {
        [self textField:maskedTextField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
    }
}

-(void)configureTextField
{
    maskedTextField = [[UITextField alloc] init];
    [maskedTextField setFrame:self.bounds];
    [self addSubview:maskedTextField];
    maskedTextField.delegate = self;
}

-(void)configureButton
{
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setAlpha:1];
    CGRect rect = self.bounds;
    [button setFrame:rect];
    [button addTarget:self action:@selector(buttonTouched) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
}

- (void)setMask: (NSString*) maskString
{
    format = maskString;
    [maskedTextField resignFirstResponder];
    maskedTextField.text = @"";
}

- (void)setNumericBlank: (NSString*) numblank alphanumericBlank: (NSString*)alphaNumBlank letterBlank:(NSString*)letBlank
{
    numericBlank = numblank;
    alphaNumericBlank = alphaNumBlank;
    letterBlank = letBlank;
    
    [maskedTextField resignFirstResponder];
    maskedTextField.text = @"";
}

-(void)buttonTouched
{
    [maskedTextField becomeFirstResponder];
}

-(UITextField*)maskedTextField
{
    return maskedTextField;
}

#pragma mark - Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self selectTextForInput:textField atRange:NSMakeRange([self calculateCaretLocation], 0)];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return [self applySimpleMaskOnTextfield:textField range:range replacementString:string];
}

#pragma mark - Main Masking Operation
- (BOOL)applySimpleMaskOnTextfield:(UITextField*)textField range:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@""])
    {
        //Delete character mode
        inputText = [inputText substringToIndex:inputText.length-(inputText.length>0)];
    }
    else
    {
        //Add character mode
        
        //dont allow a longer string to be pasted (is it disabled by the button already)
        if (string.length > 1)
        {
            return NO;
        }
        //return if the input value is different
        if (![self isStringValidForMask:string])
        {
            return NO;
        }
        //add one character
        inputText = [inputText stringByAppendingString:string];
    }
    
    NSString *finalString = @"";
    int k = 0;
    int caretLocation = -1;
    for (int i = 0; i < format.length; i++)
    {
        NSString* formatCharacter = [format substringWithRange:NSMakeRange(i, 1)];
        if ([self isSpecialCharacter:formatCharacter])
        {
            if (k < inputText.length)
            {
                NSString *inputSubstring = [inputText substringWithRange:NSMakeRange(k, 1)];
                k++;
                finalString = [finalString stringByAppendingString:inputSubstring];
            }
            else
            {
                finalString = [finalString stringByAppendingString:[self blankForSpecialCharacter:formatCharacter]];
            }
        }
        else
        {
            finalString = [finalString stringByAppendingString:formatCharacter];
        }
    }
    
    caretLocation = [self calculateCaretLocation];
    
    //set the text manually
    textField.text = finalString;
    [self selectTextForInput:textField atRange:NSMakeRange(caretLocation, 0)];
    
    return NO;
}

- (void)showMask
{
    inputText = @"";
    [self textField:maskedTextField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
}

#pragma mark - Text Field Caret placement
//taken from answer: http://stackoverflow.com/a/11532718
- (void)selectTextForInput:(UITextField *)input atRange:(NSRange)range
{
    UITextPosition *start = [input positionFromPosition:[input beginningOfDocument]
                                                 offset:range.location];
    UITextPosition *end = [input positionFromPosition:start
                                               offset:range.length];
    [input setSelectedTextRange:[input textRangeFromPosition:start toPosition:end]];
}

- (int)calculateCaretLocation
{
    int k = 0;
    int caretLoc = -1;
    for (int i = 0; i < format.length; i++)
    {
        NSString* formatCharacter = [format substringWithRange:NSMakeRange(i, 1)];
        if ([self isSpecialCharacter:formatCharacter])
        {
            if (k == inputText.length)
            {
                caretLoc = i;
            }
            k++;
        }
    }
    if (caretLoc == -1)
    {
        caretLoc = format.length;
    }
    return caretLoc;
}

- (int)specialCharacterCountForString:(NSString*)string
{
    int specialCharCount = 0;
    for (int i = 0; i < string.length; i++)
    {
        NSString* formatCharacter = [string substringWithRange:NSMakeRange(i, 1)];
        if ([self isSpecialCharacter:formatCharacter])
        {
            specialCharCount++;
        }
    }
    return specialCharCount;
}

#pragma mark - characterSet Validation

- (BOOL)isStringValidForMask: (NSString*)string
{
    int counter = 0;
    
    //iterate through the format string until the next special character slot to be edited is found
    for (int i = 0; i < format.length; i++)
    {
        NSString* formatCharacter = [format substringWithRange:NSMakeRange(i, 1)];
        if ([self isSpecialCharacter:formatCharacter])
        {
            //"counter"th special character
            
            //current mask character is to be tested with a valid character set
            if (counter == inputText.length)
            {
                NSCharacterSet* charSet = [self characterSetForSpecialCharacter:formatCharacter];
                NSRange r = [string rangeOfCharacterFromSet: charSet];
                
                if (r.location != NSNotFound)
                {
                    //string is valid for this set
                    return YES;
                }
                else
                {
                    return NO;
                }
            }
            counter++;
        }
    }
    return NO;
}

#pragma mark - Special Character (MASK_CHAR_x)

-(BOOL)isSpecialCharacter: (NSString*)specialCharacter
{
    return  [specialCharacter isEqualToString:MASK_CHAR_NUMERIC]      ||
    [specialCharacter isEqualToString:MASK_CHAR_ALPHANUMERIC] ||
    [specialCharacter isEqualToString:MASK_CHAR_LETTER];
}

-(NSString*)blankForSpecialCharacter:(NSString*)specialCharacter
{
    if ([specialCharacter isEqualToString:MASK_CHAR_NUMERIC])
    {
        return numericBlank;
    }
    else if ([specialCharacter isEqualToString:MASK_CHAR_ALPHANUMERIC])
    {
        return alphaNumericBlank;
    }
    else if ([specialCharacter isEqualToString:MASK_CHAR_LETTER])
    {
        return letterBlank;
    }
    else
    {
        return @"_";
    }
}

-(NSCharacterSet*)characterSetForSpecialCharacter: (NSString*)specialCharacter
{
    if ([specialCharacter isEqualToString:MASK_CHAR_NUMERIC])
    {
        return [NSCharacterSet decimalDigitCharacterSet];
    }
    else if ([specialCharacter isEqualToString:MASK_CHAR_ALPHANUMERIC])
    {
        return [NSCharacterSet alphanumericCharacterSet];
    }
    else if ([specialCharacter isEqualToString:MASK_CHAR_LETTER])
    {
        return [NSCharacterSet letterCharacterSet];
    }
    else
    {
        return NO;
    }
}

#pragma mark - Clear

-(void)dealloc
{
    maskedTextField.delegate = nil;
}

@end
