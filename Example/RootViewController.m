//
//  RootViewController.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/4/10.
//  Copyright Idea Shower, LLC 2010. All rights reserved.
//

#import "RootViewController.h"
#import "ExampleShareLink.h"
#import "ExampleShareImage.h"
#import "ExampleShareText.h"
#import "ExampleShareFile.h"
#import "SHK.h"

#import "SHKShareController.h"
#import "SHKShareItemController.h"

@implementation RootViewController

- (void)loadView
{
	[super loadView];
	
	self.toolbarItems = [NSArray arrayWithObjects:
						 [[[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Logout") style:UIBarButtonItemStyleBordered target:self action:@selector(logout)] autorelease],
						 nil
						 ];	
}

- (void)viewDidLoad {
	UIBarButtonItem * shareItem = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
	self.navigationItem.rightBarButtonItem = shareItem;
	[shareItem release];
	
	UIBarButtonItem * accountMgmtItem = [[UIBarButtonItem alloc] initWithTitle:@"Setup" style:UIBarButtonSystemItemAction target:self action:@selector(accountMgmtAction)];
	self.navigationItem.leftBarButtonItem = accountMgmtItem;
	[accountMgmtItem release];
}

#pragma mark -
#pragma mark Table view data source


// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 4;//5;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	switch (indexPath.row) 
	{
		case 0:
			cell.textLabel.text = SHKLocalizedString(@"Sharing a Link");
			break;
			
		case 1:
			cell.textLabel.text = SHKLocalizedString(@"Sharing an Image");
			break;
			
		case 2:
			cell.textLabel.text = SHKLocalizedString(@"Sharing Text");
			break;
			
		case 3:
			cell.textLabel.text = SHKLocalizedString(@"Sharing a File");
			break;
			
		//case 4:
		//	cell.textLabel.text = @"Logout of All Services";
		//	break;
	}

    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	switch (indexPath.row) 
	{
		case 0:
			[self.navigationController pushViewController:[[[ExampleShareLink alloc] initWithNibName:nil bundle:nil] autorelease] animated:YES];
			break;
			
		case 1:
			
			[self.navigationController pushViewController:[[[ExampleShareImage alloc] initWithNibName:nil bundle:nil] autorelease] animated:YES];
			break;
			
		case 2:
			[self.navigationController pushViewController:[[[ExampleShareText alloc] initWithNibName:nil bundle:nil] autorelease] animated:YES];
			break;
			
		case 3:
			[self.navigationController pushViewController:[[[ExampleShareFile alloc] initWithNibName:nil bundle:nil] autorelease] animated:YES];
			break;
			
		//case 4:
		//	[SHK logoutOfAll];
		//	break;			
			
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}


#pragma mark -

- (void)logout
{
	[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Logout")
								 message:SHKLocalizedString(@"Are you sure you want to logout of all share services?")
								delegate:self
					   cancelButtonTitle:SHKLocalizedString(@"Cancel")
					   otherButtonTitles:@"Logout",nil] autorelease] show];
	
	[SHK logoutOfAll];
}

- (void)shareAction {
	NSArray * shareList = [NSArray arrayWithObjects:@"http://img04.taobaocdn.com/bao/uploaded/i4/T1mj8YXkXGXXXDFUYb_095521.jpg_160x160.jpg",
						   @"http://img04.taobaocdn.com/bao/uploaded/i4/T1idNOXdhvXXbmkO70_035641.jpg_160x160.jpg",
						   @"http://img02.taobaocdn.com/bao/uploaded/i2/T1.SJNXapkXXb8EHM0_034418.jpg_160x160.jpg",
						   @"http://img02.taobaocdn.com/imgextra/i2/151642256/T2HqJnXmlbXXXXXXXX_!!151642256.jpg_310x310.jpg",
						   //@"http://img04.taobaocdn.com/bao/uploaded/i4/T1idNOXdhvXXbmkO70_035641.jpg_160x160.jpg",
						   //@"http://img02.taobaocdn.com/bao/uploaded/i2/T1.SJNXapkXXb8EHM0_034418.jpg_160x160.jpg",
						   @"http://img03.taobaocdn.com/imgextra/i3/151642256/T2mb8bXbhbXXXXXXXX_!!151642256.gif_310x310.jpg", nil];
	SHKShareItemController * shareController = [[SHKShareItemController alloc] initWithImageList:shareList];
	UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:shareController];
	[shareController release];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:navController animated:YES];
	[navController release];
}

- (void)accountMgmtAction {
	SHKShareController * controller = [[SHKShareController alloc] initWithStyle:UITableViewStyleGrouped];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
		[SHK logoutOfAll];
}


@end

