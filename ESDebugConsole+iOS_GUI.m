//
//  ESDebugConsole+iOS_GUI.m
//
//  Copyright Doug Russell 2012. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>
#import "ESDebugConsole+iOS_GUI.h"
#import "ESConsoleEntry.h"

@interface ESDebugConsole ()
@end

#define ISPAD [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
#define ISPHONE [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone

@interface ESDebugAppListTableViewController : UITableViewController
@property (nonatomic, retain) NSDictionary *allApplicationLogs;
@property (nonatomic, retain) NSArray *allApps;
@end

@interface ESDebugTableViewController : UITableViewController
@property (nonatomic, retain) NSString *applicationIdentifier;
@property (nonatomic, retain) NSArray *applicationLogs;
@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@property (nonatomic, assign) NSTimer *autoRefreshTimer;
@end

@interface ESDebugTableViewCell : UITableViewCell
@property (nonatomic, retain) UILabel *applicationIdentifierLabel;
@property (nonatomic, retain) UILabel *messageLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@end

@interface ESDebugDetailViewController : UIViewController
@property (nonatomic, retain) UITextView *textView;
@end

@implementation ESDebugConsole (iOS_GUI)

#pragma mark - 

- (void)lowMemoryWarning:(NSNotification *)notification
{
	[self.popoverController dismissPopoverAnimated:NO];
	self.popoverController = nil;
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	self.navigationController = nil;
}

#pragma mark - 

- (void)gestureRecognized:(UIGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer.state == UIGestureRecognizerStateRecognized)
		[self showFromView:gestureRecognizer.view];
}

- (void)showFromView:(UIView *)view
{
	if (view == nil)
	{
		return;
	}
	if (ISPAD)
	{
		if ([self.popoverController isPopoverVisible])
			return;
		[self.popoverController presentPopoverFromRect:CGRectMake(0, 0, 10, 10) 
												inView:view
							  permittedArrowDirections:UIPopoverArrowDirectionAny 
											  animated:YES];
	}
	else if (ISPHONE)
	{
		if (self.window.rootViewController.presentedViewController != nil)
			return;
		[self.window.rootViewController presentViewController:self.navigationController animated:YES completion:nil];
	}
}

#pragma mark - Accessors

- (UIGestureRecognizer *)gestureRecognizer
{
	return _gestureRecognizer;
}

- (void)setGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
	if (_gestureRecognizer != gestureRecognizer)
	{
		if (_gestureRecognizer != nil)
		{
			[((UIGestureRecognizer *)_gestureRecognizer).view removeGestureRecognizer:_gestureRecognizer];
		}
		_gestureRecognizer = gestureRecognizer;
	}
}

- (CGSize)consoleSizeInPopover
{
	return _consoleSizeInPopover;
}

- (void)setConsoleSizeInPopover:(CGSize)consoleSizeInPopover
{
	if (!CGSizeEqualToSize(consoleSizeInPopover, _consoleSizeInPopover))
	{
		_consoleSizeInPopover = consoleSizeInPopover;
	}
}

@end

@implementation ESDebugConsole (iOS_GUI_Private)

#pragma mark - Init/Dealloc

- (void)iOSInit
{
	UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
	if (!window)
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	if (window == nil)
	{
		[NSException raise:@"Nil Window Exception" format:@"Activated ESDebugConsole without a window to attach to"];
		return;
	}
	if (window.rootViewController == nil && ISPHONE)
	{
		[NSException raise:@"Nil Root View Controller Exception" format:@"Activated ESDebugConsole without a root view controller to attach to"];
		return;
	}
	self.window = window;
    self.consoleSizeInPopover = CGSizeZero;
	UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognized:)];
	rotationGesture.cancelsTouchesInView = NO;
	self.gestureRecognizer = rotationGesture;
	[window addGestureRecognizer:rotationGesture];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lowMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)iOSDealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

#pragma mark - Accessors

- (UIWindow *)window
{
	return _window;
}

- (void)setWindow:(UIWindow *)window
{
	if (_window != window)
	{
		_window = window;
	}
}

- (UIPopoverController *)popoverController
{
	if (_popoverController == nil)
	{
		if (!(ISPAD))
			return nil;
		_popoverController = [[UIPopoverController alloc] initWithContentViewController:self.navigationController];
	}
	return _popoverController;
}

- (void)setPopoverController:(UIPopoverController *)popoverController
{
	if (_popoverController != popoverController)
	{
		_popoverController = popoverController;
	}
}

- (UINavigationController *)navigationController
{
	if (_navigationController == nil)
	{
		ESDebugAppListTableViewController *tvc = [ESDebugAppListTableViewController new];
		if (!CGSizeEqualToSize(self.consoleSizeInPopover, CGSizeZero))
			tvc.contentSizeForViewInPopover = self.consoleSizeInPopover;
		_navigationController = [[UINavigationController alloc] initWithRootViewController:tvc];
	}
	return _navigationController;
}

- (void)setNavigationController:(UINavigationController *)navigationController
{
	if (_navigationController != navigationController)
	{
		_navigationController = navigationController;
	}
}

@end

@implementation ESDebugAppListTableViewController
@synthesize allApplicationLogs=_allApplicationLogs;
@synthesize allApps=_allApps;

#pragma mark - 

- (void)done:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)refresh:(id)sender
{
	UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[activity startAnimating];
	UIBarButtonItem *activityButton = [[UIBarButtonItem alloc] initWithCustomView:activity];
	self.navigationItem.leftBarButtonItem = activityButton;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
		NSDictionary *logs = [ESDebugConsole getConsole];
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			self.allApplicationLogs = logs;
			NSMutableArray *allApps = [[self.allApplicationLogs allKeys] mutableCopy];
			[allApps removeObject:kESDebugConsoleAllLogsKey];
			self.allApps = allApps;
			[self.tableView reloadData];
			UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
			self.navigationItem.leftBarButtonItem = refreshButton;
		});
	});
}

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"App List";
	
	if (ISPHONE)
	{
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
		self.navigationItem.rightBarButtonItem = doneButton;
	}
	
	if ([[ESDebugConsole sharedDebugConsole] respondsToSelector:@selector(sendConsoleAsEmail)])
	{
		UIBarButtonItem *email = [[UIBarButtonItem alloc] initWithTitle:@"Email Logs" style:UIBarButtonItemStyleBordered target:self action:@selector(email:)];
		if (ISPAD)
		{
			self.navigationItem.rightBarButtonItem = email;
		}
		else
		{
			self.toolbarItems = [NSArray arrayWithObjects:email, nil];
		}
		[self.navigationController setToolbarHidden:NO animated:NO];
	}
	
	[self refresh:nil];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.allApplicationLogs = nil;
	self.allApps = nil;
}

#pragma mark - 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.allApps)
		return self.allApps.count + 2;
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	}
	
	switch (indexPath.row) {
		case 0:
			cell.textLabel.text = @"All";
			break;
		case 1:
			cell.textLabel.text = @"Current";
			break;
		default:
			cell.textLabel.text = [self.allApps objectAtIndex:indexPath.row-2];
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ESDebugTableViewController *tvc = [ESDebugTableViewController new];
    tvc.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
	NSString *applicationIdentifier;
	switch (indexPath.row) {
		case 0:
			applicationIdentifier = kESDebugConsoleAllLogsKey;
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:applicationIdentifier];
			tvc.applicationIdentifier = applicationIdentifier;
			break;
		case 1:
			applicationIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleIdentifierKey];
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:applicationIdentifier];
			tvc.applicationIdentifier = applicationIdentifier;
			break;
		default:
			applicationIdentifier = [self.allApps objectAtIndex:indexPath.row-2];
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:applicationIdentifier];
			tvc.applicationIdentifier = applicationIdentifier;
			break;
	}
	[self.navigationController pushViewController:tvc animated:YES];
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

#pragma mark - Email

- (void)email:(UIBarButtonItem *)sender
{
	UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[activity startAnimating];
	UIBarButtonItem *activityButton = [[UIBarButtonItem alloc] initWithCustomView:activity];
	if (ISPAD)
		self.navigationItem.rightBarButtonItem = activityButton;
	else
		self.toolbarItems = [NSArray arrayWithObjects:activityButton, nil];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
		NSArray *logs = [[ESDebugConsole getConsole] objectForKey:kESDebugConsoleAllLogsKey];
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[[ESDebugConsole sharedDebugConsole] performSelector:@selector(setMessage:) withObject:[logs formattedConsoleString]];
			[[ESDebugConsole sharedDebugConsole] performSelector:@selector(sendConsoleAsEmail)];
			if (ISPAD)
				self.navigationItem.rightBarButtonItem = sender;
			else
				self.toolbarItems = [NSArray arrayWithObjects:sender, nil];
		});
	});
}

@end

@implementation ESDebugTableViewController
@synthesize applicationIdentifier=_applicationIdentifier;
@synthesize applicationLogs=_applicationLogs;
@synthesize segmentedControl=_segmentedControl;
@synthesize autoRefreshTimer=_autoRefreshTimer;

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Console";
	
	UIBarButtonItem *spaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	UILabel *autoRefreshLabel = [[UILabel alloc] init];
	autoRefreshLabel.text = @"AutoRefresh: ";
	autoRefreshLabel.backgroundColor = [UIColor clearColor];
	autoRefreshLabel.font = [UIFont boldSystemFontOfSize:14];
	autoRefreshLabel.textColor = [UIColor whiteColor];
	[autoRefreshLabel sizeToFit];
	UIBarButtonItem *autoRefreshLabelButton = [[UIBarButtonItem alloc] initWithCustomView:autoRefreshLabel];
	
	UISwitch *autoRefreshSwitch = [[UISwitch alloc] init];
	[autoRefreshSwitch addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem *autoRefreshSwitchButton = [[UIBarButtonItem alloc] initWithCustomView:autoRefreshSwitch];
	
	UIBarButtonItem *spaceRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	if ([[ESDebugConsole sharedDebugConsole] respondsToSelector:@selector(sendConsoleAsEmail)])
	{
		UIBarButtonItem *email = [[UIBarButtonItem alloc] initWithTitle:@"Email Logs" style:UIBarButtonItemStyleBordered target:self action:@selector(email:)];
		self.navigationItem.rightBarButtonItem = email;
	}
	
	self.toolbarItems = [NSArray arrayWithObjects:
						 spaceLeft,
						 autoRefreshLabelButton,
						 autoRefreshSwitchButton,
						 spaceRight,
						 nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.autoRefreshTimer invalidate];
	self.autoRefreshTimer = nil;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.segmentedControl = nil;
	self.applicationLogs = nil;
}

#pragma mark - 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.applicationLogs)
		return self.applicationLogs.count;
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseIdentifier = @"Cell";
	ESDebugTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
	{
		cell = [[ESDebugTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	}
	
	ESConsoleEntry *entry = [self.applicationLogs objectAtIndex:indexPath.row];
	cell.applicationIdentifierLabel.text = entry.applicationIdentifier;
	cell.messageLabel.text = entry.shortMessage;
	cell.dateLabel.text = [entry.date description];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ESDebugDetailViewController *detailViewController = [ESDebugDetailViewController new];
    detailViewController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
	detailViewController.textView.text = [NSString stringWithFormat:@"%@", [self.applicationLogs objectAtIndex:indexPath.row]];
	[self.navigationController pushViewController:detailViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// This assumes that the table view cells content view is as wide as the actual table,
	// which isn't necessarily true, but works fine here
	CGSize size = [[[self.applicationLogs objectAtIndex:indexPath.row] shortMessage] sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 20, 10000) lineBreakMode:NSLineBreakByWordWrapping];
	// add in the padding for the applicationIdentifier and date
	size.height += 60;
	return size.height;
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

#pragma mark - AutoRefresh

- (void)switchToggled:(UISwitch *)sender
{
	if (self.autoRefreshTimer && [self.autoRefreshTimer isValid])
	{
		[self.autoRefreshTimer invalidate];
		self.autoRefreshTimer = nil;
	}
	else
	{
		self.autoRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(refreshTimer:) userInfo:nil repeats:YES];
	}
}

- (void)refreshTimer:(NSTimer *)timer
{
	//NSLog(@"Refresh");
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		NSArray *newLogs = [[ESDebugConsole getConsole] objectForKey:self.applicationIdentifier];
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			self.applicationLogs = newLogs;
			[self.tableView reloadData];
		});
	});
}

#pragma mark - Email

- (void)email:(id)sender
{
	[[ESDebugConsole sharedDebugConsole] performSelector:@selector(setMessage:) withObject:[self.applicationLogs formattedConsoleString]];
	[[ESDebugConsole sharedDebugConsole] performSelector:@selector(sendConsoleAsEmail)];
}

@end

@implementation ESDebugTableViewCell
@synthesize applicationIdentifierLabel=_applicationIdentifierLabel;
@synthesize messageLabel=_messageLabel;
@synthesize dateLabel=_dateLabel;

#pragma mark - 

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self != nil)
	{
		_applicationIdentifierLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_applicationIdentifierLabel.font = [UIFont boldSystemFontOfSize:18];
		[self.contentView addSubview:_applicationIdentifierLabel];
		_messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_messageLabel.numberOfLines = 0;
		_messageLabel.font = [UIFont systemFontOfSize:17];
		_messageLabel.textColor = [UIColor darkGrayColor];
		[self.contentView addSubview:_messageLabel];
		_dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:_dateLabel];
	}
	return self;
}

#pragma mark - 

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	self.applicationIdentifierLabel.frame = CGRectMake(10, 10, self.contentView.frame.size.width - 20, 18);
	CGSize size = CGSizeMake(self.contentView.frame.size.width - 20, 18);
	if (self.messageLabel.text.length)
		size = [self.messageLabel.text sizeWithFont:[self.messageLabel font] constrainedToSize:CGSizeMake(size.width, 10000) lineBreakMode:NSLineBreakByWordWrapping];
	self.messageLabel.frame = CGRectMake(10, 30, size.width, size.height);
	self.dateLabel.frame = CGRectMake(10, CGRectGetMaxY(self.messageLabel.frame), self.contentView.frame.size.width - 20, 18);
}

@end

@implementation ESDebugDetailViewController
@synthesize textView=_textView;

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Details";
	
	self.textView.frame = self.view.bounds;
	
	[self.view addSubview:self.textView];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.textView = nil;
}

#pragma mark -

- (UITextView *)textView
{
	if (_textView == nil)
	{
		_textView = [[UITextView alloc] initWithFrame:CGRectZero];
		_textView.editable = NO;
		_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return _textView;
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end
