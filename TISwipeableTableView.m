//
//  TISwipeableTableView.m
//  TISwipeableTableView
//
//  Created by Tom Irving on 28/05/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TISwipeableTableView.h"

#pragma mark -
#pragma mark TISwipeableTableView
#pragma mark -
//==========================================================
// - TISwipeableTableView
//==========================================================

@interface TISwipeableTableView (Private)
- (BOOL)supportsSwipingForCellAtPoint:(CGPoint)point;
- (void)highlightTouchedRow;
@end

@implementation TISwipeableTableView
@synthesize swipeDelegate;
@synthesize indexOfVisibleBackView;

NSInteger const kMinimumGestureLength = 18;
NSInteger const kMaximumVariance = 8;

#pragma mark -
#pragma mark Init

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	
	if ((self = [super initWithFrame:frame style:style])){
		[self setDelaysContentTouches:NO];
        
	}
	
	return self;
}

#pragma mark -
#pragma mark Helpers
- (BOOL)supportsSwipingForCellAtPoint:(CGPoint)point {
	
	NSIndexPath * indexPath = [self indexPathForRowAtPoint:point];
	UITableViewCell * testCell = [self cellForRowAtIndexPath:indexPath];
	
	BOOL supportsSwiping = NO;
	
	if ([testCell isKindOfClass:[TISwipeableTableViewCell class]]){
		supportsSwiping = ((TISwipeableTableViewCell *)testCell).shouldSupportSwiping;
	}
	
	// Thanks to Martin Destagnol (@mdestagnol) for this delegate method.
	if (supportsSwiping && [swipeDelegate respondsToSelector:@selector(tableView:shouldSwipeCellAtIndexPath:)]){
		supportsSwiping = [swipeDelegate tableView:self shouldSwipeCellAtIndexPath:indexPath];
	}
	
	return supportsSwiping;
}

- (void)highlightTouchedRow {
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:gestureStartPoint];
	UITableViewCell * testCell = [self cellForRowAtIndexPath:indexPath];
	if ([testCell isKindOfClass:[TISwipeableTableViewCell class]] && ![testCell isSelected]){
        [self selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
	}
}

#pragma mark -
#pragma mark Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * touch = [touches anyObject];
	gestureStartPoint = [touch locationInView:self];
	[self hideVisibleBackView:YES];
    
    if (![self supportsSwipingForCellAtPoint:gestureStartPoint]) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([self supportsSwipingForCellAtPoint:gestureStartPoint]){
		NSIndexPath *indexPath = [self indexPathForRowAtPoint:gestureStartPoint];
		
		UITouch * touch = [touches anyObject];
		CGPoint currentPosition = [touch locationInView:self];
		
		CGFloat deltaX = fabsf(gestureStartPoint.x - currentPosition.x);
		CGFloat deltaY = fabsf(gestureStartPoint.y - currentPosition.y);
		
		if (deltaX >= kMinimumGestureLength && deltaY <= kMaximumVariance){
			
			[self setScrollEnabled:NO];
			
			TISwipeableTableViewCell * cell = (TISwipeableTableViewCell *)[self cellForRowAtIndexPath:indexPath];
			
			if (cell.backView.hidden && [touch.view isKindOfClass:[TISwipeableTableViewCellView class]]){
				
                [self deselectRowAtIndexPath:[self indexPathForSelectedRow] animated:YES];
                
				[cell revealBackView];
				
				if ([swipeDelegate respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
					[swipeDelegate tableView:self didSwipeCellAtIndexPath:indexPath];
				}
				
				[self setIndexOfVisibleBackView:[self indexPathForCell:cell]];
			}
			
			[self setScrollEnabled:YES];
		}
	} else {
		[super touchesMoved:touches withEvent:event];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * touch = [touches anyObject];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:gestureStartPoint];
	
	if ([self supportsSwipingForCellAtPoint:gestureStartPoint]){
		
		TISwipeableTableViewCell * cell = (TISwipeableTableViewCell *)[self cellForRowAtIndexPath:indexPath];
        
        if ([[cell backView] isHidden]) {
            if (![cell isSelected]) {
                [self performSelector:@selector(highlightTouchedRow) withObject:nil];
            }
            
            if ([touch.view isKindOfClass:[TISwipeableTableViewCellView class]] && cell.isSelected 
                && !cell.contentViewMoving && [self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]){
                [self.delegate tableView:self didSelectRowAtIndexPath:indexPath];
            }
        }
		
	} else {
		[super touchesEnded:touches withEvent:event];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([self supportsSwipingForCellAtPoint:gestureStartPoint]){
		
        UITableViewCell *cell = [self cellForRowAtIndexPath:[self indexPathForRowAtPoint:gestureStartPoint]];
        NSIndexPath *indexPath = [self indexPathForRowAtPoint:gestureStartPoint];
        if ([cell isSelected]) {
            if ([[self delegate] respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)]) {
                indexPath = [[self delegate] tableView:self willDeselectRowAtIndexPath:indexPath];
            }
            
            [self deselectRowAtIndexPath:indexPath animated:YES];
            
            if ([[self delegate] respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)]) {
                [[self delegate] tableView:self didDeselectRowAtIndexPath:indexPath];
            }
        }
		
	} else {
		[super touchesCancelled:touches withEvent:event];
	}
}

#pragma mark -
#pragma mark Other Stuff
- (void)hideVisibleBackView:(BOOL)animated {
	
	if (indexOfVisibleBackView){
		
		if (animated){
			[(TISwipeableTableViewCell *)[self cellForRowAtIndexPath:indexOfVisibleBackView] hideBackView];
		}
		else
		{
			[(TISwipeableTableViewCell *)[self cellForRowAtIndexPath:indexOfVisibleBackView] resetViews];
		}
		
		[self setIndexOfVisibleBackView:nil];
	}
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TISwipeableTableView %p 'Handling swiping like a boss since 1861'>", self];
}

- (void)dealloc {
	
	[self setDelegate:nil];
	[indexOfVisibleBackView release];
	[super dealloc];
}

@end

#pragma mark -
#pragma mark TISwipeableTableViewCell
#pragma mark -
//==========================================================
// - TISwipeableTableViewCell
//==========================================================

@implementation TISwipeableTableViewCellView
- (void)drawRect:(CGRect)rect {
	
	if (!self.hidden){
		[(TISwipeableTableViewCell *)[self superview] drawContentView:rect];
	}
	else
	{
		[super drawRect:rect];
	}
}
@end

@implementation TISwipeableTableViewCellBackView
- (void)drawRect:(CGRect)rect {
	
	if (!self.hidden){
		[(TISwipeableTableViewCell *)[self superview] drawBackView:rect];
	}
	else
	{
		[super drawRect:rect];
	}
}

@end

@interface TISwipeableTableViewCell (Private)
- (void)initialSetup;
- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX;
@end

@implementation TISwipeableTableViewCell
@synthesize backView;
@synthesize contentViewMoving;
@synthesize shouldSupportSwiping;
@synthesize shouldBounce;

#pragma mark -
#pragma mark Init / Overrides
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
		[self initialSetup];
    }
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self initialSetup];
	}
	
	return self;
}

- (void)initialSetup {
	
	[self setBackgroundColor:[UIColor clearColor]];
	
	contentView = [[TISwipeableTableViewCellView alloc] initWithFrame:CGRectZero];
	[contentView setClipsToBounds:YES];
	[contentView setOpaque:YES];
	[contentView setBackgroundColor:[UIColor clearColor]];
	
	backView = [[TISwipeableTableViewCellBackView alloc] initWithFrame:CGRectZero];
	[backView setOpaque:YES];
	[backView setClipsToBounds:YES];
	[backView setHidden:YES];
	[backView setBackgroundColor:[UIColor clearColor]];
	
	[self addSubview:backView];
	[self addSubview:contentView];
	
	[contentView release];
	[backView release];
	
	contentViewMoving = NO;
	shouldSupportSwiping = YES;
	shouldBounce = YES;
	
	[self setSelected:NO];
	[self hideBackView];
}

- (void)prepareForReuse {
	
	[self resetViews];
	[super prepareForReuse];
}

- (void)setFrame:(CGRect)aFrame {
	
	[super setFrame:aFrame];
	
	CGRect newBounds = self.bounds;
	newBounds.size.height -= 1;
	[backView setFrame:newBounds];	
	[contentView setFrame:newBounds];
}

- (void)setNeedsDisplay {
	
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
	[backView setNeedsDisplay];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
	// Having an accessory buggers swiping right up, so we override.
	// It's easier just to draw the accessory yourself.
}

- (void)setAccessoryView:(UIView *)accessoryView {
	// Same as above.
}

- (void)setSelected:(BOOL)flag {
	[super setSelected:flag];
	[self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Subclass Methods
// Implement the following in a subclass
- (void)drawContentView:(CGRect)rect {
	
}

- (void)drawBackView:(CGRect)rect {
	
}

// Optional implementation
- (void)backViewWillAppear {
	
}

- (void)backViewDidAppear {
	
}

- (void)backViewWillDisappear {
	
}

- (void)backViewDidDisappear {
	
}

//===============================//

#pragma mark -
#pragma mark Back View Show / Hide
- (void)revealBackView {
	
	if (!contentViewMoving && backView.hidden){
		
		contentViewMoving = YES;
		
		[backView.layer setHidden:NO];
		[backView setNeedsDisplay];
		
		[contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
		[contentView.layer setPosition:CGPointMake(contentView.frame.size.width, contentView.layer.position.y)];
		
		CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
		[animation setRemovedOnCompletion:NO];
		[animation setDelegate:self];
		[animation setDuration:0.14];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
		[contentView.layer addAnimation:animation forKey:@"reveal"];
		
		[self backViewWillAppear];
	}
}

- (void)hideBackView {
	
	if (!backView.hidden){
		
		contentViewMoving = YES;
		
		CGFloat hideDuration = 0.09;
		
		[backView.layer setOpacity:0.0];
		CABasicAnimation * hideAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		[hideAnimation setFromValue:[NSNumber numberWithFloat:1.0]];
		[hideAnimation setToValue:[NSNumber numberWithFloat:0.0]];
		[hideAnimation setDuration:hideDuration];
		[hideAnimation setRemovedOnCompletion:NO];
		[hideAnimation setDelegate:self];
		[backView.layer addAnimation:hideAnimation forKey:@"hide"];
		
		CGFloat originalX = contentView.layer.position.x;
		[contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
		[contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
		[contentView.layer addAnimation:[self bounceAnimationWithHideDuration:hideDuration initialXOrigin:originalX] 
								 forKey:@"bounce"];
		
		
		[self backViewWillDisappear];
	}
}

- (void)resetViews {
	
	[contentView.layer removeAllAnimations];
	[backView.layer removeAllAnimations];
	
	contentViewMoving = NO;
	
	[contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
	[contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
	
	[backView.layer setHidden:YES];
	[backView.layer setOpacity:1.0];
	
	[self backViewDidDisappear];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	
	if (anim == [contentView.layer animationForKey:@"reveal"]){
		[contentView.layer removeAnimationForKey:@"reveal"];
		
		[self backViewDidAppear];
        UITableView *tableView = (UITableView *) [self superview];
        [tableView deselectRowAtIndexPath:[tableView indexPathForCell:self] animated:YES];
		
		contentViewMoving = NO;
	}
	
	if (anim == [contentView.layer animationForKey:@"bounce"]){
		[contentView.layer removeAnimationForKey:@"bounce"];
		[self resetViews];
	}
	
	if (anim == [backView.layer animationForKey:@"hide"]){
		[backView.layer removeAnimationForKey:@"hide"];
	}
}

- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX {
	
	CABasicAnimation * animation0 = [CABasicAnimation animationWithKeyPath:@"position.x"];
	[animation0 setFromValue:[NSNumber numberWithFloat:originalX]];
	[animation0 setToValue:[NSNumber numberWithFloat:0]];
	[animation0 setDuration:hideDuration];
	[animation0 setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
	[animation0 setBeginTime:0];
	
	CAAnimationGroup * hideAnimations = [CAAnimationGroup animation];
	[hideAnimations setAnimations:[NSArray arrayWithObject:animation0]];
	
	CGFloat fullDuration = hideDuration;
	
	if (shouldBounce){
		
		CGFloat bounceDuration = 0.04;
		
		CABasicAnimation * animation1 = [CABasicAnimation animationWithKeyPath:@"position.x"];
		[animation1 setFromValue:[NSNumber numberWithFloat:0]];
		[animation1 setToValue:[NSNumber numberWithFloat:-20]];
		[animation1 setDuration:bounceDuration];
		[animation1 setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
		[animation1 setBeginTime:hideDuration];
		
		CABasicAnimation * animation2 = [CABasicAnimation animationWithKeyPath:@"position.x"];
		[animation2 setFromValue:[NSNumber numberWithFloat:-20]];
		[animation2 setToValue:[NSNumber numberWithFloat:15]];
		[animation2 setDuration:bounceDuration];
		[animation2 setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
		[animation2 setBeginTime:(hideDuration + bounceDuration)];
		
		CABasicAnimation * animation3 = [CABasicAnimation animationWithKeyPath:@"position.x"];
		[animation3 setFromValue:[NSNumber numberWithFloat:15]];
		[animation3 setToValue:[NSNumber numberWithFloat:0]];
		[animation3 setDuration:bounceDuration];
		[animation3 setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
		[animation3 setBeginTime:(hideDuration + (bounceDuration * 2))];
		
		[hideAnimations setAnimations:[NSArray arrayWithObjects:animation0, animation1, animation2, animation3, nil]];
		
		fullDuration = hideDuration + (bounceDuration * 3);
	}
	
	[hideAnimations setDuration:fullDuration];
	[hideAnimations setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
	[hideAnimations setDelegate:self];
	[hideAnimations setRemovedOnCompletion:NO];
	
	return hideAnimations;
}

#pragma mark -
#pragma mark Other
- (NSString *)description {
	
	NSString * extraInfo = backView.hidden ? @"ContentView visible": @"BackView visible";
	return [NSString stringWithFormat:@"<TISwipeableTableViewCell %p '%@'>", self, extraInfo];
}

@end
