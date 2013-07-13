//
//  TISwipeableTableView.h
//  TISwipeableTableView
//
//  Created by Tom Irving on 28/05/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without modification,
//	are permitted provided that the following conditions are met:
//
//		1. Redistributions of source code must retain the above copyright notice, this list of
//		   conditions and the following disclaimer.
//
//		2. Redistributions in binary form must reproduce the above copyright notice, this list
//         of conditions and the following disclaimer in the documentation and/or other materials
//         provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY TOM IRVING "AS IS" AND ANY EXPRESS OR IMPLIED
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOM IRVING OR
//	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <UIKit/UIKit.h>

//==========================================================
// - TISwipeableTableViewController
//==========================================================

@interface TISwipeableTableViewController : UITableViewController
@property (nonatomic, strong, readonly) NSIndexPath * indexOfVisibleBackView;

// Thanks to Martin Destagnol (@mdestagnol) for this method.
- (BOOL)tableView:(UITableView *)tableView shouldSwipeCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView revealBackViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)tableView:(UITableView *)tableView hideVisibleBackView:(BOOL)animated;

@end

//==========================================================
// - TISwipeableTableViewCell
//==========================================================

@interface TISwipeableTableViewCellView : UIView
@end

@interface TISwipeableTableViewCellBackView : UIView
@end

@interface TISwipeableTableViewCell : UITableViewCell <UIGestureRecognizerDelegate>
@property (nonatomic, readonly) UIView * backView;
@property (nonatomic, assign) BOOL contentViewMoving;
@property (nonatomic, assign) BOOL shouldBounce;

- (void)drawContentView:(CGRect)rect;
- (void)drawBackView:(CGRect)rect;

- (void)backViewWillAppear:(BOOL)animated;
- (void)backViewDidAppear:(BOOL)animated;
- (void)backViewWillDisappear:(BOOL)animated;
- (void)backViewDidDisappear:(BOOL)animated;

- (void)revealBackViewAnimated:(BOOL)animated;
- (void)hideBackViewAnimated:(BOOL)animated;

@end
