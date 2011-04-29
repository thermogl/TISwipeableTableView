//
//  RootViewController.m
//  SwipeableExample
//
//  Created by Tom Irving on 16/06/2010.
//  Copyright Tom Irving 2010. All rights reserved.
//

#import "RootViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation RootViewController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	
	TISwipeableTableView * aTableView = [[TISwipeableTableView alloc] initWithFrame:self.tableView.frame style:self.tableView.style];
	[aTableView setDelegate:self];
	[aTableView setDataSource:self];
	[aTableView setSwipeDelegate:self];
	[aTableView setRowHeight:54];
	[self setTableView:aTableView];
	[aTableView release];
	
	[self.navigationItem setTitle:@"Swipeable TableView"];
	
    [super viewDidLoad];
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
	
	ExampleCell * cell = (ExampleCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[[ExampleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	[cell setText:[NSString stringWithFormat:@"Swipe me! (Row %i)", indexPath.row]];
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	[cell setDelegate:self];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Cell Selected" 
														 message:[NSString stringWithFormat:@"You tapped cell %i", indexPath.row]
														delegate:nil 
											   cancelButtonTitle:@"OK" 
											   otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


static void completionCallback(SystemSoundID soundID, void * clientData) {
	AudioServicesRemoveSystemSoundCompletion(soundID);
}

- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath {
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"tick" ofType:@"wav"];
	NSURL * fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
	
	SystemSoundID soundID;
	AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &soundID);
	AudioServicesPlaySystemSound(soundID);
	AudioServicesAddSystemSoundCompletion (soundID, NULL, NULL, completionCallback, NULL);
}

- (void)cellBackButtonWasTapped:(ExampleCell *)cell {
	NSLog(@"%@", cell);
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	[(TISwipeableTableView*)self.tableView hideVisibleBackView:NO];
}

@end

