//
//  FlickrPhotoTVC.m
//  Shutterbug
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "FlickrPhotoTVC.h"
#import "FlickrFetcher.h"
#import "ImageViewController.h"

@interface FlickrPhotoTVC() <UISplitViewControllerDelegate>
@end

@implementation FlickrPhotoTVC

- (void)setPhotos:(NSArray *)photos
{
    _photos = photos;
    [self.tableView reloadData];
}

#pragma mark - UISplitViewControllerDelegate

- (void)awakeFromNib
{
    self.splitViewController.delegate = self;
}

- (BOOL)splitViewController:(UISplitViewController *)sender
   shouldHideViewController:(UIViewController *)master
              inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)sender
     willHideViewController:(UIViewController *)master
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popover
{
	barButtonItem.title = @"Menu";
		// setSplitViewBarButtonItem: must put the bar button somewhere on screen
		// probably in a UIToolbar or a UINavigationBar in the detail (right-side)
	id detailViewController = [self.splitViewController.viewControllers lastObject]; //viewcontrollers is an array, [0]master [1]detail
	[detailViewController setSplitViewBarButtonItem:barButtonItem]; // calling the setter
}

-(void) splitViewController:sender
	 willShowViewController:master
  invalidatingBarButtonItem:barButtonItem
{
	id detailViewController = [self.splitViewController.viewControllers lastObject];
	[detailViewController setSplitViewBarButtonItem:nil];
}
#pragma mark - Bar button transfer

-(id)splitViewDetailWithBarButtonItem
{
	id detail = [self.splitViewController.viewControllers lastObject]; // get detail VC
	if (![detail respondsToSelector:@selector(setSplitViewBarButtonItem:)] ||
		![detail respondsToSelector:@selector(splitViewBarButtonItem)]){
		detail = nil;
	}
	return detail;
}

	// This method is necessary when a new detail VC is instantiated as a result of a segue. The current bar button item will disappear, so grab the current one and transfer it to the new detail vc by setting a property. The setter of the property in the new detail VC will put it on its toolbar
- (void)transferSplitViewBarButtonItemToViewController:(id)destinationViewController
{
	id detail = [self splitViewDetailWithBarButtonItem]; // get detail VC
    UIBarButtonItem *buttonToBeTransferred = [detail splitViewBarButtonItem]; // get pointer to button in detail
//	[detail setSplitViewBarButtonItem:nil]; // set button ivar to nil (I don't know why that is necessary)
	if (buttonToBeTransferred)	// if there is a button: transfer it to the VC that is replacing the current one
		[destinationViewController setSplitViewBarButtonItem:buttonToBeTransferred];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show Image"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
					[self transferSplitViewBarButtonItemToViewController:segue.destinationViewController];
                    NSURL *url = [FlickrFetcher urlForPhoto:self.photos[indexPath.row] format:FlickrPhotoFormatLarge];
                    [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:url];
                    [segue.destinationViewController setTitle:[self titleForRow:indexPath.row]]; // pass title to 
					[self addToRecent:self.photos[indexPath.row]];
                }
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photos count];
}

- (NSString *)titleForRow:(NSUInteger)row
{
    return [self.photos[row][FLICKR_PHOTO_TITLE] description]; // description because could be NSNull
}

- (NSString *)subtitleForRow:(NSUInteger)row
{
    return [[self.photos[row] valueForKeyPath:FLICKR_PHOTO_DESCRIPTION] description]; // description because could be NSNull
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flickr Photo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [self titleForRow:indexPath.row];
    cell.detailTextLabel.text = [self subtitleForRow:indexPath.row];
    
    return cell;
}

#pragma mark - Recent Photos

#define RECENT_PHOTOS_KEY @"Recent Photo"

- (void)addToRecent:(NSDictionary *)currentPhoto {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *recentPhotos = [[defaults objectForKey:RECENT_PHOTOS_KEY]mutableCopy];
    if (!recentPhotos) recentPhotos = [[NSMutableArray alloc]init];
    
    if ((currentPhoto) && (![recentPhotos containsObject:currentPhoto]))[recentPhotos insertObject:currentPhoto atIndex:0];
    if (recentPhotos.count>25) {
        [recentPhotos removeLastObject];
    }
    
    [defaults setObject:recentPhotos forKey:RECENT_PHOTOS_KEY];
    [defaults synchronize];
}

@end
