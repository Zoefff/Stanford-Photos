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
	barButtonItem.title = @"Master"; // use a better word than “Master”!
									 // setSplitViewBarButtonItem: must put the bar button somewhere on screen
									 // probably in a UIToolbar or a UINavigationBar in the detail (right-side)
	id detailViewController = [self.splitViewController.viewControllers lastObject];
	[detailViewController setSplitViewBarButtonItem:barButtonItem];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
								duration:(NSTimeInterval)duration{
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		id detailViewController = [self.splitViewController.viewControllers lastObject];
		[detailViewController setSplitViewBarButtonItem:nil];
	
	}
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show Image"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
                    NSURL *url = [FlickrFetcher urlForPhoto:self.photos[indexPath.row] format:FlickrPhotoFormatLarge];
                    [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:url];
                    [segue.destinationViewController setTitle:[self titleForRow:indexPath.row]];
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
    return [self.photos[row][FLICKR_PHOTO_OWNER] description]; // description because could be NSNull
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
