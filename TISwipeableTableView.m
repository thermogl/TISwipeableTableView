//
//  TISwipeableTableView.m
//  TISwipeableTableView
//
//  Created by Tom Irving on 28/05/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TISwipeableTableView.h"

//==========================================================
// - TISwipeableTableView
//==========================================================

@interface TISwipeableTableView (Private)
- (BOOL)supportsSwipingForCellAtPoint:(CGPoint)point;
@end


@implementation TISwipeableTableView
@synthesize swipeDelegate;
@synthesize indexOfVisibleBackView;

#define kMinimumGestureLength 18
#define kMaximumVariance 8

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	
	if ((self = [super initWithFrame:frame style:style])){
		[self setDelaysContentTouches:NO];
	}
	
	return self;
}

- (void)highlightTouchedRow {
		
	UITableViewCell * testCell = [self cellForRowAtIndexPath:[self indexPathForRowAtPoint:gestureStartPoint]];
	
	if ([testCell isKindOfClass:[TISwipeableTableViewCell class]]){
		[(TISwipeableTableViewCell *)testCell setSelected:YES];
	}
}

- (BOOL)supportsSwipingForCellAtPoint:(CGPoint)point {
	
	UITableViewCell * testCell = [self cellForRowAtIndexPath:[self indexPathForRowAtPoint:point]];
	if ([testCell isKindOfClass:[TISwipeableTableViewCell class]]){
		return [(TISwipeableTableViewCell *)testCell shouldSupportSwiping];
	}
	
	return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self hideVisibleBackView:YES];
	
	UITouch * touch = [touches anyObject];
	gestureStartPoint = [touch locationInView:self];
	
	if ([self supportsSwipingForCellAtPoint:gestureStartPoint]){
		[self performSelector:@selector(highlightTouchedRow) withObject:nil afterDelay:0.06];	
	}
	else
	{
		[super touchesBegan:touches withEvent:event];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if ([self supportsSwipingForCellAtPoint:gestureStartPoint]){
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(highlightTouchedRow) object:nil];
		
		UITouch * touch = [touches anyObject];
		CGPoint currentPosition = [touch locationInView:self];
		
		CGFloat deltaX = fabsf(gestureStartPoint.x - currentPosition.x);
		CGFloat deltaY = fabsf(gestureStartPoint.y - currentPosition.y);
	
		if (deltaX >= kMinimumGestureLength && deltaY <= kMaximumVariance){
			
			[self setScrollEnabled:NO];
		
			TISwipeableTableViewCell * cell = (TISwipeableTableViewCell *)[self cellForRowAtIndexPath:[self indexPathForRowAtPoint:gestureStartPoint]];
			
			if (cell.backView.hidden && [touch.view isKindOfClass:[TISwipeableTableViewCellView class]]){
				
				[cell revealBackView];
				
				if (swipeDelegate && [swipeDelegate respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
					[swipeDelegate tableView:self didSwipeCellAtIndexPath:[self indexPathForRowAtPoint:gestureStartPoint]];
				}
				
				[self setIndexOfVisibleBackView:[self indexPathForCell:cell]];
			}
			
			[self setScrollEnabled:YES];
		}
	}
	else
	{
		[super touchesMoved:touches withEvent:event];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch * touch = [touches anyObject];
	
	if ([self supportsSwipingForCellAtPoint:gestureStartPoint]){
		
		TISwipeableTableViewCell * cell = (TISwipeableTableViewCell *)[self cellForRowAtIndexPath:[self indexPathForRowAtPoint:gestureStartPoint]];
	
		if ([touch.view isKindOfClass:[TISwipeableTableViewCellView class]] && cell.isSelected 
			&& !cell.contentViewMoving && [self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]){
			[self.delegate tableView:self didSelectRowAtIndexPath:[self indexPathForCell:cell]];
		}
		
		[self touchesCancelled:touches withEvent:event];
	}
	else
	{
		[super touchesEnded:touches withEvent:event];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if ([self supportsSwipingForCellAtPoint:gestureStartPoint]){
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(highlightTouchedRow) object:nil];
		[(TISwipeableTableViewCell *)[self cellForRowAtIndexPath:[self indexPathForRowAtPoint:gestureStartPoint]] setSelected:NO];
		
	}
	else
	{
		[super touchesCancelled:touches withEvent:event];
	}
}

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
- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX;
@end

@implementation TISwipeableTableViewCell
@synthesize contentView;
@synthesize backView;
@synthesize contentViewMoving;
@synthesize selected;
@synthesize shouldSupportSwiping;
@synthesize shouldBounce;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
		
		[self setBackgroundColor:[UIColor clearColor]];
		
		TISwipeableTableViewCellView * aView = [[TISwipeableTableViewCellView alloc] initWithFrame:CGRectZero];
		[aView setClipsToBounds:YES];
		[aView setOpaque:YES];
		[aView setBackgroundColor:[UIColor clearColor]];
		[self setContentView:aView];
		[aView release];
		
		TISwipeableTableViewCellBackView * anotherView = [[TISwipeableTableViewCellBackView alloc] initWithFrame:CGRectZero];
		[anotherView setOpaque:YES];
		[anotherView setClipsToBounds:YES];
		[anotherView setHidden:YES];
		[anotherView setBackgroundColor:[UIColor clearColor]];
		[self setBackView:anotherView];
		[anotherView release];
		
		// Backview must be added first!
		// DO NOT USE sendSubviewToBack:
		
		[self addSubview:backView];
		[self addSubview:contentView];
		
		[self setContentViewMoving:NO];
		[self setSelected:NO];
		[self setShouldSupportSwiping:YES];
		[self setShouldBounce:YES];
		[self hideBackView];
    }
	
    return self;
}

- (void)prepareForReuse {
	
	[self resetViews];
	[super prepareForReuse];
}

- (void)setFrame:(CGRect)aFrame {
	
	[super setFrame:aFrame];
	
	CGRect bound = [self bounds];
	bound.size.height -= 1;
	bound.size.width += 20;
	[backView setFrame:bound];	
	[contentView setFrame:bound];
}

- (void)setNeedsDisplay {
	
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
	[backView setNeedsDisplay];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
	
	// Having an accessory buggers swiping right up, so we disable it.
	[self setShouldSupportSwiping:NO];
	[super setAccessoryType:accessoryType];
}

- (void)setAccessoryView:(UIView *)accessoryView {
	
	// Same thing here
	[self setShouldSupportSwiping:NO];
	[super setAccessoryView:accessoryView];
}

- (void)setSelected:(BOOL)flag {
	
	selected = flag;
	[self setNeedsDisplay];
}

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

- (void)revealBackView {
	
	if (!contentViewMoving && backView.hidden){
		
		[self setContentViewMoving:YES];
		
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
	
	if (!contentViewMoving && !backView.hidden){
		
		[self setContentViewMoving:YES];
		
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
	
	[self setContentViewMoving:NO];
	
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
		[self setSelected:NO];
		[self setContentViewMoving:NO];
	}
	
	if (anim == [contentView.layer animationForKey:@"bounce"]){
		[contentView.layer removeAnimationForKey:@"bounce"];
		[self resetViews];
	}
		
	if (anim == [backView.layer animationForKey:@"hide"]){
		[backView.layer removeAnimationForKey:@"hide"];
	}
}

- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX; {
	
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

- (NSString *)description {
	
	NSString * extraInfo = backView.hidden ? @"ContentView visible": @"BackView visible";
	
	return [NSString stringWithFormat:@"<TISwipeableTableViewCell %p '%@'>", self, extraInfo];
}

- (void)dealloc {
	[contentView release];
	[backView release];
    [super dealloc];
}

@end
