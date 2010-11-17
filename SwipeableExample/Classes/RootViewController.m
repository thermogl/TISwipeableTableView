//
//  RootViewController.m
//  SwipeableExample
//
//  Created by Tom Irving on 16/06/2010.
//  Copyright Tom Irving 2010. All rights reserved.
//

#import "RootViewController.h"

@implementation RootViewController
@synthesize audioPlayers;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithStyle:(UITableViewStyle)style {
	
	if ((self = [super initWithStyle:style])){
		
		TISwipeableTableView * aTableView = [[TISwipeableTableView alloc] initWithFrame:self.tableView.frame style:style];
		[aTableView setDelegate:self];
		[aTableView setDataSource:self];
		[aTableView setSwipeDelegate:self];
		[aTableView setRowHeight:54];
		[self setTableView:aTableView];
		[aTableView release];
		
		[self setAudioPlayers:[NSMutableArray array]];
		[self.navigationItem setTitle:@"Swipeable TableView"];
	}
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath {
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"tick" ofType:@"wav"];
	AVAudioPlayer * audioPlayer = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:path] error:nil];
	[audioPlayer play];
	[audioPlayer setDelegate:self];
	[audioPlayers addObject:audioPlayer];
	[audioPlayer release];
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	
	[(TISwipeableTableView*)self.tableView hideVisibleBackView:YES];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	
	[audioPlayers removeObject:player];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[audioPlayers release];
    [super dealloc];
}


@end

