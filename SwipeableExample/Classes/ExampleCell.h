//
//  ExampleCell.h
//  SwipeableExample
//
//  Created by Tom Irving on 16/06/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TISwipeableTableView.h"

@interface ExampleCell : TISwipeableTableViewCell {
	
	NSString * text;

}

@property (nonatomic, retain) NSString * text;

- (void)drawShadowsWithHeight:(CGFloat)shadowHeight opacity:(CGFloat)opacity InRect:(CGRect)rect forContext:(CGContextRef)context;

@end
