//
//  ExampleCell.m
//  SwipeableExample
//
//  Created by Tom Irving on 16/06/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "ExampleCell.h"

@implementation ExampleCell
@synthesize text;

- (void)setText:(NSString *)aString {
	
	if (aString != text){
		[text release];
		text = [aString retain];
		[self setNeedsDisplay];
	}
}

- (void)drawContentView:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	UIColor * backgroundColour = [UIColor whiteColor];
	UIColor * textColour = [UIColor blackColor];
	
	if (self.isSelected) {
		backgroundColour = [UIColor colorWithRed:0.189 green:0.495 blue:0.903 alpha:1];
		textColour = [UIColor whiteColor];
	}
	
	[backgroundColour set];
	CGContextFillRect(context, rect);
	
	[textColour set];
	
	UIFont * textFont = [UIFont boldSystemFontOfSize:22];
	
	CGSize textSize = [text sizeWithFont:textFont constrainedToSize:rect.size];
	[text drawInRect:CGRectMake((rect.size.width / 2) - (textSize.width / 2), 
								(rect.size.height / 2) - (textSize.height / 2),
								textSize.width, textSize.height)
			withFont:textFont];
	
	if (self.isSelected){
		[self drawShadowsWithHeight:7 opacity:0.1 InRect:rect forContext:context];
	}
}

- (void)drawBackView:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[UIImage imageNamed:@"meshpattern.png"] drawAsPatternInRect:rect];
	[self drawShadowsWithHeight:10 opacity:0.3 InRect:rect forContext:context];
}

- (void)drawShadowsWithHeight:(CGFloat)shadowHeight opacity:(CGFloat)opacity InRect:(CGRect)rect forContext:(CGContextRef)context {
	
	CGColorSpaceRef space = CGBitmapContextGetColorSpace(context);
	
	CGFloat topComponents[8] = {0, 0, 0, opacity, 0, 0, 0, 0};
	CGGradientRef topGradient = CGGradientCreateWithColorComponents(space, topComponents, nil, 2);
	CGPoint finishTop = CGPointMake(rect.origin.x, rect.origin.y + shadowHeight);
	CGContextDrawLinearGradient(context, topGradient, rect.origin, finishTop, kCGGradientDrawsAfterEndLocation);
	
	CGFloat bottomComponents[8] = {0, 0, 0, 0, 0, 0, 0, opacity};
	CGGradientRef bottomGradient = CGGradientCreateWithColorComponents(space, bottomComponents, nil, 2);
	CGPoint startBottom = CGPointMake(rect.origin.x, rect.size.height - shadowHeight);
	CGPoint finishBottom = CGPointMake(rect.origin.x, rect.size.height);
	CGContextDrawLinearGradient(context, bottomGradient, startBottom, finishBottom, kCGGradientDrawsAfterEndLocation);
	
	CGGradientRelease(topGradient);
	CGGradientRelease(bottomGradient);
}

- (void)dealloc {
	
	[text release];
    [super dealloc];
}

@end
