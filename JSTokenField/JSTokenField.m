//
//	Copyright 2011 James Addyman (JamSoft). All rights reserved.
//	
//	Redistribution and use in source and binary forms, with or without modification, are
//	permitted provided that the following conditions are met:
//	
//		1. Redistributions of source code must retain the above copyright notice, this list of
//			conditions and the following disclaimer.
//
//		2. Redistributions in binary form must reproduce the above copyright notice, this list
//			of conditions and the following disclaimer in the documentation and/or other materials
//			provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY JAMES ADDYMAN (JAMSOFT) ``AS IS'' AND ANY EXPRESS OR IMPLIED
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JAMES ADDYMAN (JAMSOFT) OR
//	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//	The views and conclusions contained in the software and documentation are those of the
//	authors and should not be interpreted as representing official policies, either expressed
//	or implied, of James Addyman (JamSoft).
//

#import "JSTokenField.h"
#import "JSTokenButton.h"
#import "JSBackspaceReportingTextField.h"
#import <QuartzCore/QuartzCore.h>

NSString *const JSDeletedTokenKey = @"JSDeletedTokenKey";

#define HORIZONTAL_SPACING 6
#define VERTICAL_SPACING 3
#define HEIGHT_PADDING 3
#define MIN_TEXTFIELD_WIDTH 60

@interface JSTokenField ();

- (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj;
- (void)deleteHighlightedToken;

- (void)commonSetup;
@end


@implementation JSTokenField

@synthesize tokens = _tokens;
@synthesize textField = _textField;
@synthesize label = _label;

+ (CGFloat)heightWithTokens:(NSArray *)tokens title:(NSString *)title constrainedToWidth:(CGFloat)width
{    
    CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]+1]                      
                                  forWidth:width/2.0f
                             lineBreakMode:NSLineBreakByTruncatingMiddle];
    
    CGFloat availableWidth;
    CGFloat left = titleSize.width + HORIZONTAL_SPACING;
    CGFloat top = 0;
    
    CGFloat maxTokenHeight = 0;
    
    for (UIButton *token in tokens) {
        availableWidth = width - left;

        CGSize tokenSize = token.frame.size;
        
        if (token.frame.size.height > maxTokenHeight) maxTokenHeight = token.frame.size.height;
        if (!(!left || tokenSize.width <= availableWidth)) {
            top += tokenSize.height + VERTICAL_SPACING;
            left = 0;
            maxTokenHeight = token.frame.size.height;
        }
        left += tokenSize.width + HORIZONTAL_SPACING;
    }
    
    availableWidth = width - left;
    if (!(!left || MIN_TEXTFIELD_WIDTH <= availableWidth)) {
        top += maxTokenHeight + VERTICAL_SPACING + HEIGHT_PADDING;
        left = 0;
        availableWidth = width;
    }
    
    CGSize textFieldSize = [@"Ag" sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];

    return MAX(25.0f,top + HEIGHT_PADDING + textFieldSize.height + 1);
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]){
        [self commonSetup];
    }
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup {
    CGRect frame = self.frame;
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, frame.size.height)];
    [_label setBackgroundColor:[UIColor clearColor]];
    [_label setTextColor:[UIColor colorWithRed:180.0/255.0 green:180.0/255.0 blue:180.0/255.0 alpha:1.0f]];
    [_label setFont:[UIFont systemFontOfSize:[UIFont systemFontSize]+1]];
    [_label setLineBreakMode:NSLineBreakByTruncatingMiddle];
    
    [self addSubview:_label];
    
    //		self.layer.borderColor = [[UIColor blueColor] CGColor];
    //		self.layer.borderWidth = 1.0;
    
    _tokens = [[NSMutableArray alloc] init];
    _textField = [[JSBackspaceReportingTextField alloc] initWithFrame:frame];
    [_textField setDelegate:self];
    [_textField setFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
    [_textField setBorderStyle:UITextBorderStyleNone];
    [_textField setBackground:nil];
    [_textField setBackgroundColor:[UIColor clearColor]];
    [_textField setContentVerticalAlignment:UIControlContentVerticalAlignmentBottom];
    
    //		[_textField.layer setBorderColor:[[UIColor redColor] CGColor]];
    //		[_textField.layer setBorderWidth:1.0];
    
    [self addSubview:_textField];
    
    [self.textField addTarget:self action:@selector(textFieldWasUpdated:) forControlEvents:UIControlEventEditingChanged];
}

- (void)addTokenWithTitle:(NSString *)string representedObject:(id)obj
{
	NSString *aString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
	if ([aString length])
	{
		JSTokenButton *token = [self tokenWithString:aString representedObject:obj];
        token.parentField = self;
		[_tokens addObject:token];
		
        [self addSubview:token];
        
        if (self.tokensLimit) {
            self.textField.userInteractionEnabled = self.tokens.count < self.tokensLimit;
        } else {
            self.textField.userInteractionEnabled = TRUE;
        }
        
		if ([self.delegate respondsToSelector:@selector(tokenField:didAddToken:representedObject:)])
		{
			[self.delegate tokenField:self didAddToken:aString representedObject:obj];
		}
        
		[self setNeedsLayout];
	}
}

- (void)removeTokenWithTest:(BOOL (^)(JSTokenButton *token))test {
    JSTokenButton *tokenToRemove = nil;
    for (JSTokenButton *token in [_tokens reverseObjectEnumerator]) {
        if (test(token)) {
            tokenToRemove = token;
            break;
        }
    }
    
    if (tokenToRemove) {
        if (tokenToRemove.isFirstResponder) {
            [_textField becomeFirstResponder];
        }
        [tokenToRemove removeFromSuperview];
        
        [_tokens removeObject:tokenToRemove];
        
        if (self.tokensLimit) {
            self.textField.userInteractionEnabled = self.tokens.count < self.tokensLimit;
        } else {
            self.textField.userInteractionEnabled = TRUE;
        }
        
        if ([self.delegate respondsToSelector:@selector(tokenField:didRemoveToken:representedObject:)])
        {
				NSString *tokenName = [tokenToRemove titleForState:UIControlStateNormal];
				[self.delegate tokenField:self didRemoveToken:tokenName representedObject:tokenToRemove.representedObject];

		}
	}
    
    [self setNeedsLayout];
}

- (void)removeTokenForString:(NSString *)string
{
    [self removeTokenWithTest:^BOOL(JSTokenButton *token) {
        return [[token titleForState:UIControlStateNormal] isEqualToString:string];
    }];
}

- (void)removeTokenWithRepresentedObject:(id)representedObject {
    [self removeTokenWithTest:^BOOL(JSTokenButton *token) {
        return [[token representedObject] isEqual:representedObject];
    }];
}

- (void)removeAllTokens {
	NSArray *tokensCopy = [_tokens copy];
	for (JSTokenButton *button in tokensCopy) {
		[self removeTokenWithTest:^BOOL(JSTokenButton *token) {
			return token == button;
		}];
	}
}

- (void)deleteHighlightedToken
{
	for (int i = 0; i < [_tokens count]; i++)
	{
		_deletedToken = [_tokens objectAtIndex:i];
		if ([_deletedToken isToggled])
		{
			NSString *tokenName = [_deletedToken titleForState:UIControlStateNormal];
			if ([self.delegate respondsToSelector:@selector(tokenField:shouldRemoveToken:representedObject:)]) {
				BOOL shouldRemove = [self.delegate tokenField:self
											shouldRemoveToken:tokenName
											representedObject:_deletedToken.representedObject];
				if (shouldRemove == NO) {
					return;
				}
			}
			
			[_deletedToken removeFromSuperview];
			[_tokens removeObject:_deletedToken];
			
            if (self.tokensLimit) {
                self.textField.userInteractionEnabled = self.tokens.count < self.tokensLimit;
            } else {
                self.textField.userInteractionEnabled = TRUE;
            }
            
			if ([self.delegate respondsToSelector:@selector(tokenField:didRemoveToken:representedObject:)])
			{
				[self.delegate tokenField:self didRemoveToken:tokenName representedObject:_deletedToken.representedObject];
			}

            [self setNeedsLayout];
		}
	}
}

- (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj
{
	JSTokenButton *token = [JSTokenButton tokenWithString:string representedObject:obj];

	[token addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
	
	return token;
}

- (void)layoutSubviews
{
    CGSize labelSize = [self.label sizeThatFits:CGSizeMake(self.bounds.size.width/2.0f, self.bounds.size.height)];
	
    self.label.frame = CGRectMake(0, HEIGHT_PADDING, labelSize.width, labelSize.height);
    
    CGFloat availableWidth;
    CGFloat left = labelSize.width + HORIZONTAL_SPACING;
    CGFloat top = 0;
    
    CGFloat maxTokenHeight = 0;
    
    for (UIButton *token in self.tokens) {
        availableWidth = self.bounds.size.width - left;
        
        if (token.frame.size.height > maxTokenHeight) maxTokenHeight = token.frame.size.height;
        if (!(!left || token.frame.size.width <= availableWidth)) {
            top += token.frame.size.height + VERTICAL_SPACING;
            left = 0;
            maxTokenHeight = token.frame.size.height;
        }
        
        token.frame = CGRectMake(left, top, MIN(token.width,self.bounds.size.width), token.frame.size.height);
        
        left += token.frame.size.width + HORIZONTAL_SPACING;
    }
    
    availableWidth = self.bounds.size.width - left;
    if (!(!left || MIN_TEXTFIELD_WIDTH <= availableWidth)) {
        top += maxTokenHeight + VERTICAL_SPACING;
        left = 0;
        availableWidth = self.bounds.size.width;
    }

    //CGFloat height = self.label.frame.origin.y + self.label.frame.size.height;
    
    CGSize textFieldSize = [@"Ag" sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
    
    self.textField.frame = CGRectMake(left, top+1, availableWidth, textFieldSize.height + HEIGHT_PADDING);
}


- (void)toggle:(id)sender
{
	for (JSTokenButton *token in _tokens)
	{
		[token setToggled:NO];
	}
	
	JSTokenButton *token = (JSTokenButton *)sender;
	[token setToggled:YES];
    [token becomeFirstResponder];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(tokenFieldDidBeginEditing:)]) {
        [self.delegate tokenFieldDidBeginEditing:self];
    }
}

- (void)textFieldWasUpdated:(UITextField *)sender {
    if ([self.delegate respondsToSelector:@selector(tokenFieldTextDidChange:)]) {
        [self.delegate tokenFieldTextDidChange:self];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@""] && NSEqualRanges(range, NSMakeRange(0, 0)))
	{
        JSTokenButton *token = [_tokens lastObject];
		if (!token) {
			return NO;
		}
		
		NSString *name = [token titleForState:UIControlStateNormal];
		// If we don't allow deleting the token, don't even bother letting it highlight
		BOOL responds = [self.delegate respondsToSelector:@selector(tokenField:shouldRemoveToken:representedObject:)];
		if (responds == NO || [self.delegate tokenField:self shouldRemoveToken:name representedObject:token.representedObject]) {
			[token becomeFirstResponder];
		}
		return NO;
	}
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (_textField == textField) {
        if ([self.delegate respondsToSelector:@selector(tokenFieldShouldReturn:)]) {
            return [self.delegate tokenFieldShouldReturn:self];
        }
    }
	
	return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(tokenFieldDidEndEditing:)]) {
        [self.delegate tokenFieldDidEndEditing:self];
        return;
    }
    else if ([[textField text] length] > 1)
    {
        [self addTokenWithTitle:[textField text] representedObject:[textField text]];
        [textField setText:nil];
    }
}

@end
