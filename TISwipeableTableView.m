//
//  TISwipeableTableView.m
//  TISwipeableTableView
//
//  Created by Tom Irving on 28/05/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TISwipeableTableView.h"
#import <QuartzCore/QuartzCore.h>

//==========================================================
// - TISwipeableTableViewController
//==========================================================

@interface TISwipeableTableViewController ()
@property (nonatomic, strong) NSIndexPath * indexOfVisibleBackView;
@end

@implementation TISwipeableTableViewController
@synthesize indexOfVisibleBackView = _indexOfVisibleBackView;

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return ([indexPath compare:_indexOfVisibleBackView] == NSOrderedSame) ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self tableView:tableView hideVisibleBackView:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldSwipeCellAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath {
	
	[self tableView:tableView hideVisibleBackView:YES];
	[self setIndexOfVisibleBackView:indexPath];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self tableView:(UITableView *)scrollView hideVisibleBackView:YES];
}

- (void)tableView:(UITableView *)tableView revealBackViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
{
	UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
	
	[self tableView:tableView hideVisibleBackView:animated];
	
	if ([cell respondsToSelector:@selector(revealBackViewAnimated:)]){
		[(TISwipeableTableViewCell *)cell revealBackViewAnimated:animated];
		[self setIndexOfVisibleBackView:indexPath];
	}
}

- (void)tableView:(UITableView *)tableView hideVisibleBackView:(BOOL)animated {
	
	UITableViewCell * cell = [tableView cellForRowAtIndexPath:_indexOfVisibleBackView];
	if ([cell respondsToSelector:@selector(hideBackViewAnimated:)]){
		[(TISwipeableTableViewCell *)cell hideBackViewAnimated:animated];
		[self setIndexOfVisibleBackView:nil];
	}
}


@end

//==========================================================
// - TISwipeableTableViewCell
//==========================================================

@interface UIView (FindSwipeableCellSuperview)
@property (nonatomic, readonly) TISwipeableTableViewCell * tisw_findSuperview;
@property (nonatomic, readonly) UITableView * tisw_findTableview;
@end

@implementation UIView (FindSwipeableCellSuperview)
- (TISwipeableTableViewCell *)tisw_findSuperview {

	UIView * superview = self.superview;
	if ([superview isKindOfClass:[TISwipeableTableViewCell class]]) return (TISwipeableTableViewCell *)superview;
	else if (superview) return superview.tisw_findSuperview;
	else return nil;
}

- (UITableView *)tisw_findTableview {
	UIView * tableView = self.superview;
	if ([tableView isKindOfClass:[UITableView class]]) return (UITableView *)tableView;
	else if (tableView) return tableView.tisw_findTableview;
	else return nil;
}

@end

@implementation TISwipeableTableViewCellView
- (void)drawRect:(CGRect)rect {
	[self.tisw_findSuperview drawContentView:rect];
}
@end

@implementation TISwipeableTableViewCellBackView
- (void)drawRect:(CGRect)rect {
	[self.tisw_findSuperview drawBackView:rect];
}

@end

@interface TISwipeableTableViewCell (Private)
- (void)initialSetup;
- (void)resetViews:(BOOL)animated;
- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX;
@end

@implementation TISwipeableTableViewCell {
	UIView * _contentView;
	UITableViewCellSelectionStyle _oldStyle;
}
@synthesize contentView = _contentView;
@synthesize backView = _backView;
@synthesize contentViewMoving = _contentViewMoving;
@synthesize shouldBounce = _shouldBounce;

#pragma mark - Init / Overrides
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
		[self initialSetup];
    }
	
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self initialSetup];
	}
	
	return self;
}

- (void)initialSetup {
	
	[self setBackgroundColor:[UIColor clearColor]];
	
	_contentView = [[TISwipeableTableViewCellView alloc] initWithFrame:CGRectZero];
	[_contentView setClipsToBounds:YES];
	[_contentView setOpaque:YES];
	
	UISwipeGestureRecognizer * swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(cellWasSwiped:)];
	[swipeRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft |
								   UISwipeGestureRecognizerDirectionRight)];
	[_contentView addGestureRecognizer:swipeRecognizer];
	
	_backView = [[TISwipeableTableViewCellBackView alloc] initWithFrame:CGRectZero];
	[_backView setOpaque:YES];
	[_backView setClipsToBounds:YES];
	[_backView setHidden:YES];
	
	[self addSubview:_backView];
	[self addSubview:_contentView];
	
	
	_contentViewMoving = NO;
	_shouldBounce = YES;
	_oldStyle = self.selectionStyle;
}

- (void)prepareForReuse {
	
	[self resetViews:NO];
	[super prepareForReuse];
}

- (void)setFrame:(CGRect)aFrame {
	
	[super setFrame:aFrame];
	
	CGRect newBounds = self.bounds;
	newBounds.size.height -= 1;
	[_backView setFrame:newBounds];	
	[_contentView setFrame:newBounds];
}

- (void)setNeedsDisplay {
	
	[super setNeedsDisplay];
	if (!_contentView.hidden) [_contentView setNeedsDisplay];
	if (!_backView.hidden) [_backView setNeedsDisplay];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
	// Having an accessory buggers swiping right up, so we override.
	// It's easier just to draw the accessory yourself.
}

- (void)setAccessoryView:(UIView *)accessoryView {
	// Same as above.
}

- (void)setHighlighted:(BOOL)highlighted {
	[self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	[super setHighlighted:highlighted animated:animated];
	[self setNeedsDisplay];
}

- (void)setSelected:(BOOL)flag {
	[self setSelected:flag animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	[self setNeedsDisplay];
}

#pragma mark - Subclass Methods
// Implement the following in a subclass
- (void)drawContentView:(CGRect)rect {
	
}

- (void)drawBackView:(CGRect)rect {
	
}

// Optional implementation
- (void)backViewWillAppear:(BOOL)animated {
	
}

- (void)backViewDidAppear:(BOOL)animated {
	
}

- (void)backViewWillDisappear:(BOOL)animated {
	
}

- (void)backViewDidDisappear:(BOOL)animated {
	
}

//===============================//

#pragma mark - Back View Show / Hide
- (void)cellWasSwiped:(UISwipeGestureRecognizer *)recognizer {
	
	UITableView * tableView = self.tisw_findTableview;
	
	id delegate = tableView.nextResponder; // Hopefully this is a TISwipeableTableViewController.
	if(![delegate isKindOfClass:[TISwipeableTableViewController class]])
        delegate = [delegate nextResponder];
    
	if ([delegate respondsToSelector:@selector(tableView:shouldSwipeCellAtIndexPath:)]){
		
		NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
		
		if ([delegate tableView:tableView shouldSwipeCellAtIndexPath:myIndexPath]){
			
			[self revealBackViewAnimated:YES];
			
			if ([delegate respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
				[delegate tableView:tableView didSwipeCellAtIndexPath:myIndexPath];
			}
		}
	}
}

- (void)revealBackViewAnimated:(BOOL)animated {
	
	if (!_contentViewMoving && _backView.hidden){
		
		_contentViewMoving = YES;
		
		[_backView.layer setHidden:NO];
		[_backView setNeedsDisplay];
		
		[self backViewWillAppear:animated];
		
		_oldStyle = self.selectionStyle;
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		[_contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
		[_contentView.layer setPosition:CGPointMake(_contentView.frame.size.width, _contentView.layer.position.y)];
		
		if (animated){
			
			CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
			[animation setRemovedOnCompletion:NO];
			[animation setDelegate:self];
			[animation setDuration:0.14];
			[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
			[_contentView.layer addAnimation:animation forKey:@"reveal"];
		}
		else
		{
			[self backViewDidAppear:animated];
			[self setSelected:NO];
			
			_contentViewMoving = NO;
		}
	}
}

- (void)hideBackViewAnimated:(BOOL)animated {
	
	if (!_backView.hidden){
		
		_contentViewMoving = YES;
		
		[self backViewWillDisappear:animated];
		
		if (animated){
			
			CGFloat hideDuration = 0.09;
			
			[_backView.layer setOpacity:0.0];
			CABasicAnimation * hideAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
			[hideAnimation setFromValue:[NSNumber numberWithFloat:1.0]];
			[hideAnimation setToValue:[NSNumber numberWithFloat:0.0]];
			[hideAnimation setDuration:hideDuration];
			[hideAnimation setRemovedOnCompletion:NO];
			[hideAnimation setDelegate:self];
			[_backView.layer addAnimation:hideAnimation forKey:@"hide"];
			
			CGFloat originalX = _contentView.layer.position.x;
			[_contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
			[_contentView.layer setPosition:CGPointMake(0, _contentView.layer.position.y)];
			[_contentView.layer addAnimation:[self bounceAnimationWithHideDuration:hideDuration initialXOrigin:originalX] 
									 forKey:@"bounce"];
			
			
		}
		else
		{
			[self resetViews:NO];
		}
	}
}

- (void)resetViews:(BOOL)animated {
	
	[_contentView.layer removeAllAnimations];
	[_backView.layer removeAllAnimations];
	
	_contentViewMoving = NO;
	
	[_contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
	[_contentView.layer setPosition:CGPointMake(0, _contentView.layer.position.y)];
	
	[_backView.layer setHidden:YES];
	[_backView.layer setOpacity:1.0];
	
	[self setSelectionStyle:_oldStyle];
	
	[self backViewDidDisappear:animated];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	
	if (anim == [_contentView.layer animationForKey:@"reveal"]){
		[_contentView.layer removeAnimationForKey:@"reveal"];
		
		[self backViewDidAppear:YES];
		[self setSelected:NO];
		
		_contentViewMoving = NO;
	}
	
	if (anim == [_contentView.layer animationForKey:@"bounce"]){
		[_contentView.layer removeAnimationForKey:@"bounce"];
		[self resetViews:YES];
	}
	
	if (anim == [_backView.layer animationForKey:@"hide"]){
		[_backView.layer removeAnimationForKey:@"hide"];
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
	
	if (_shouldBounce){
		
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

#pragma mark - Other
- (NSString *)description {
	
	NSString * extraInfo = _backView.hidden ? @"ContentView visible": @"BackView visible";
	return [NSString stringWithFormat:@"<TISwipeableTableViewCell %p; '%@'>", self, extraInfo];
}
@end
