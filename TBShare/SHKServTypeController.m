//
//  SHKServTypeController.m
//  ShareKit
//
//  Created by HanFeng on 11-1-21.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

#import "SHKServTypeController.h"

#import "SHKSharer.h"
#import "UIImage+ImageWithName.h"

#define VIEW_TITLE @"添加新帐号"

@interface SHKServTypeController ()

//! 从支持的分享服务中初始化需要授权的服务信息
- (void)prepareServiceNeedAuthorized;

@end


@implementation SHKServTypeController

@synthesize shareServiceList;
@synthesize serviceDictionary;


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = VIEW_TITLE;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateService:) name:SERVICE_AUTHORIZED object:nil];
	
	[self.tableView setBackgroundColor:[UIColor clearColor]];
	
	NSMutableDictionary * servDictionary = [NSMutableDictionary dictionary];
	self.serviceDictionary = servDictionary;
    
    [self prepareServiceNeedAuthorized];
}

- (void)prepareServiceNeedAuthorized {
    for (Class sharer in shareServiceList) {
        NSAssert1([sharer isSubclassOfClass:[SHKSharer class]], @"％@ undefined", sharer);
        if (![sharer isServiceAuthorized]) {
            [serviceDictionary setObject:[sharer sharerTitle] forKey:[sharer sharerId]];
        }
    }
}

- (void)updateService:(NSNotification *)notification 
{
	NSString * authorizedService = [notification object];
	NSLog(@"authorizedService: %@", authorizedService);
	[serviceDictionary removeObjectForKey:authorizedService];
    
    //注册到已打开自动分享服务
    SHKSharer * sharer = [[SHK authorizedService] objectForKey:authorizedService];
    [sharer setShouldAutoShare:YES];
	
	//[self.tableView reloadData];
	
	[self.navigationController popViewControllerAnimated:YES];
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
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[serviceDictionary allValues] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	NSString * key = [[serviceDictionary allKeys] objectAtIndex:[indexPath row]];
    cell.imageView.image = [UIImage imageWithName:[NSClassFromString(key) sharerIcon]];
    
	cell.textLabel.text = [serviceDictionary valueForKey:key];
	//cell.textLabel.textAlignment = UITextAlignmentLeft;
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * selected = [[serviceDictionary allValues] objectAtIndex:[indexPath row]];
	NSLog(@"%s row:%d service:%@", __FUNCTION__, [indexPath row], selected);
	NSArray * selectedKeys = [serviceDictionary allKeysForObject:selected];
	if ([selectedKeys count] == 1) {
		NSString * selectedKey = [selectedKeys objectAtIndex:0];
		NSLog(@"selectedKey: %@", selectedKey);
        
        Class selectedService = NSClassFromString(selectedKey);
        NSAssert1([selectedService isSubclassOfClass:[SHKSharer class]], @"%@ is not defined", selectedKey);
        
        SHKSharer * sharer = [[selectedService alloc] init];
        [sharer setIsOnlyAuthorize:YES];
        [sharer authorize];
        [sharer release];
	}else {
		NSLog(@"this line shouldn't be executed");
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
	self.serviceDictionary = nil;
    self.shareServiceList = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:SERVICE_AUTHORIZED object:nil];
}


- (void)dealloc {
    [shareServiceList release];
	[serviceDictionary release];
    [super dealloc];
}


@end

