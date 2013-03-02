//
//  FlickrTagTVC.m
//  Stanford Photos
//
//  Created by JML on 01/03/2013.
//  Copyright (c) 2013 -TDM-. All rights reserved.
//

#import "FlickrTagTVC.h"
#import "FlickrFetcher.h"

#define SKIP_TAGS @[@"cs193pspot", @"portrait", @"landscape"]


@interface FlickrTagTVC () <UISplitViewControllerDelegate>

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSDictionary *photosForTag;

@end

@implementation FlickrTagTVC

-(void)getPhotoTags{
	NSMutableArray *tags = [[NSMutableArray alloc]init];
	NSMutableDictionary *photosForTag = [[NSMutableDictionary alloc]init];
	
	for (NSDictionary *photo in self.photos) {
		NSArray *tagsForPhoto = [photo[FLICKR_TAGS] componentsSeparatedByString:@" "];
		for (NSString *tag in tagsForPhoto){
			if (![SKIP_TAGS containsObject:tag]) {
				if (!photosForTag[tag]) {
					NSMutableArray *photosForThisTag = [@[photo] mutableCopy];
					[photosForTag setObject:photosForThisTag forKey:tag];
					[tags addObject:tag];
				} else {
					[photosForTag[tag] addObject:photo];
				}
			}
		}
	}
	self.photosForTag = photosForTag;
	self.tags = [tags sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)awakeFromNib
{
    self.splitViewController.delegate = self;
	self.photos = [FlickrFetcher stanfordPhotos];
	[self getPhotoTags];
	
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show List Of Photos"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setPhotos:)]) {
                    
                    [segue.destinationViewController performSelector:@selector(setPhotos:) withObject:self.photosForTag[self.tags[indexPath.row]]];
                    [segue.destinationViewController setTitle:[self titleForRow:indexPath.row]];
                }
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tags count];
}

- (NSString *)titleForRow:(NSUInteger)row
{
    return [self.tags[row] capitalizedString]; // description because could be NSNull
}

- (NSString *)subtitleForRow:(NSUInteger)row
{
    return [NSString stringWithFormat:@"%d photos",[self.photosForTag[self.tags[row]]count]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flickr Tag";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
		// Configure the cell...
    cell.textLabel.text = [self titleForRow:indexPath.row];
    cell.detailTextLabel.text = [self subtitleForRow:indexPath.row];
    
    return cell;
}

@end
