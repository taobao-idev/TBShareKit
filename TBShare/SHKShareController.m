//
//  SHKShareController.m
//  ShareKit
//
//  Created by HanFeng on 11-1-21.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

#import "SHKShareController.h"
#import "SHKServTypeController.h"

#import "SHK.h"
#import "SHKSharer.h"
#import "UIImage+ImageWithName.h"

#define VIEW_TITLE @"账号设置"

@interface SHKShareController () 

//! 加载已经授权的服务相关的帐号信息
- (void)loadSharedServiceData;

@end

@implementation SHKShareController

@synthesize shareServiceList;
@synthesize accountDictionary;


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	SHKLog(@"%s", __FUNCTION__);
    [super viewDidLoad];
	self.title = VIEW_TITLE;
	
	self.tableView.backgroundColor = [UIColor clearColor];
	
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
    self.shareServiceList = [SHK sharedService];
    
	NSMutableDictionary * servDictionary = [NSMutableDictionary dictionary];
	self.accountDictionary = servDictionary;
}

- (void)backAction {
	NSLog(@"%s", __FUNCTION__);
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
	SHKLog(@"%s", __FUNCTION__);
    [super viewWillAppear:animated];
	
	[self loadSharedServiceData];
	
	if ([accountDictionary count] == 0) {
		[self.navigationItem.rightBarButtonItem setEnabled:NO];
	}else {
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}
	
	[self.tableView reloadData];
}

- (void)loadSharedServiceData {
    for (SHKSharer * sharer in [[SHK authorizedService] allValues]) {
        if ([sharer isAuthorized]) {
         	NSString * account = [SHK getAuthValueForKey:@"account" forSharer:[sharer sharerId]];
            [accountDictionary setObject:account == nil?@"default":account forKey:[sharer sharerId]];   
        }
    }
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	SHKLog(@"%s", __FUNCTION__);
	
	// 根据是否在编辑状态返回，编辑时不显示添加帐号一行
	if (self.editing && [accountDictionary count] != 0) {
		return 1;
	}else if (self.editing && [accountDictionary count] == 0) {
		return 0;
	}

	
	if ([accountDictionary count] == 0 || [accountDictionary count] == [shareServiceList count]) {
		return 1;
	}
	
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	SHKLog(@"%s section:%d", __FUNCTION__, section);
	
	if ([accountDictionary count] != 0 && section == 0) {
		return [accountDictionary count];
	}else {
		return 1;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHKLog(@"%s section:%d row:%d", __FUNCTION__, [indexPath section], [indexPath row]);
	
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		if ([accountDictionary count] != 0 && [indexPath section] == 0) {
			//[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		}
    }
	
	static NSString * createIdentifier = @"Create";
	UITableViewCell * createCell = [tableView dequeueReusableCellWithIdentifier:createIdentifier];
	if (createCell == nil) {
		createCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:createIdentifier] autorelease];
	}
    
    // Configure the cell...
	if ([accountDictionary count] != 0 && [indexPath section] == 0) {
		NSString * servKey = [[accountDictionary allKeys] objectAtIndex:[indexPath row]];
        SHKSharer * sharer = (SHKSharer *)[[SHK authorizedService] objectForKey:servKey];
        cell.imageView.image = [UIImage imageWithName:[sharer sharerIcon]];
		cell.textLabel.text = [NSString stringWithFormat:@"%@", [accountDictionary objectForKey:servKey]];
		
        /*
		UISwitch * switchButton = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchButton setOn:[sharer shouldAutoShare]];
		[switchButton setTag:[indexPath row]];
		[switchButton addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
		cell.accessoryView = switchButton;
		[switchButton release];*/
		return cell;
	}else {
		createCell.imageView.image = [UIImage imageWithName:@"account_add"];
		createCell.textLabel.text = @"添加新帐号";
		//createCell.textLabel.textAlignment = UITextAlignmentCenter;
		return createCell;
	}
}

/*
 * 打开或关闭自动分享功能
 * 创建新帐号时默认打开自动分享功能，可以手动关闭该分享
 */
- (void)switchValueChanged:(id)sender {
	SHKLog(@"%s", __FUNCTION__);
	
	UISwitch * servSwitch = (UISwitch *)sender;
	NSString * changeKey = [[accountDictionary allKeys] objectAtIndex:[servSwitch tag]];
	NSLog(@"tag:%d changeKey:%@", [servSwitch tag], changeKey);
    
    SHKSharer * sharer = [[SHK authorizedService] objectForKey:changeKey];
    if (![servSwitch isOn]) {
        [sharer setShouldAutoShare:NO];
    }else {
        [sharer setShouldAutoShare:YES];
    }

}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	if (([accountDictionary count] != 0 && [indexPath section] == 1 ) 
		|| ([accountDictionary count] == 0 && [indexPath section] == 0)) {
		return NO;
	}
	
    return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	NSLog(@"%s", __FUNCTION__);
	
	[super setEditing:editing animated:animated];
	
	if (editing && [accountDictionary count] == 0) {
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"no account needs to edit" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		return;
	}
	
	if (editing && [accountDictionary count] != [shareServiceList count]) {
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
	}else if (!editing && [accountDictionary count] == 0) {
		[self.navigationItem.rightBarButtonItem setEnabled:NO]; //when no account existed, disable edit button item
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	}else if (!editing && [accountDictionary count] != [shareServiceList count]) {
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
	}
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    SHKLog(@"%s section:%d row:%d", __FUNCTION__, [indexPath section], [indexPath row]);
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.		
		NSString * key = [[accountDictionary allKeys] objectAtIndex:[indexPath row]];
		NSLog(@"delete:%@", key);
		[accountDictionary removeObjectForKey:key];
		
		[NSClassFromString(key) logout]; //logout service for the deleted account
		
		if ([accountDictionary count] == 0) {
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
			return;
		}
		
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    } 
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SHKLog(@"%s", __FUNCTION__);
	
	if ([accountDictionary count] != 0 && [indexPath section] == 0) {
		
	}else {
		//guide user to create new account for sharing
		SHKServTypeController * servTypeController = [[SHKServTypeController alloc] initWithStyle:UITableViewStyleGrouped];
        [servTypeController setShareServiceList:shareServiceList];
		[self.navigationController pushViewController:servTypeController animated:YES];
		[servTypeController release];
	}

}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
    self.shareServiceList =  nil;
	self.accountDictionary = nil;
}


- (void)dealloc {
    [shareServiceList release];
	[accountDictionary release];
    [super dealloc];
}


@end

