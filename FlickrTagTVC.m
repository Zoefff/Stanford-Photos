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

-(void)setTags:(NSArray *)tags{
	if (_tags!=tags){ // only set and reload if tags have changed
		_tags=tags;
		[self.tableView reloadData];
	}
}

-(void)getPhotoTags{
	NSMutableDictionary *photosForTag = [[NSMutableDictionary alloc]init]; // array with all photos per tag
	
	for (NSDictionary *photo in self.photos) {
		NSArray *tagsForPhoto = [photo[FLICKR_TAGS] componentsSeparatedByString:@" "]; // first load all tags for each photo in an array
		for (NSString *tag in tagsForPhoto){ // then loop through each tag
			if (![SKIP_TAGS containsObject:tag]) { // skip all SKIP_TAGS
				if (!photosForTag[tag]) { // of there are no photos associated with this tag
					NSMutableArray *photosForThisTag = [@[photo] mutableCopy]; // create a mutuable array, initially consisting of the first ohoto associated with this tag
					[photosForTag setObject:photosForThisTag forKey:tag]; //add the tag and array to the dictionary
				} else {
					[photosForTag[tag] addObject:photo]; // tag is already in dict, add this photo to the array associated with this tag
				}
			}
		}
	}
	self.photosForTag = photosForTag;
	self.tags = [[photosForTag allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)awakeFromNib
{
    self.splitViewController.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self refreshPhotos];
	// no ctrl-drag possible, therefore done in code 
	[self.refreshControl addTarget:self
							action:@selector(refreshPhotos)
				  forControlEvents:UIControlEventValueChanged];
}

	// As asked about in class, this mechanism could conceivably be abstract in superclass.
	// It would then want to call something like "fetchPhotos" which subclasses could override
	//  (and which this class would implement with "return [FlickrFetcher latestGeoreferencedPhotos]")
	// and in that case this method would not want to call itself "loadLatestPhotosFromFlickr"
	//  (probaby something like "loadPhotos").
	// We're doing it here (instead of superclass) just to make the queueing more obvious.


-(IBAction)refreshPhotos{ // no ctrl-drag possible, therefore done in code
	[self.refreshControl beginRefreshing]; // start animation of the spinner
	dispatch_queue_t loaderQ = dispatch_queue_create("flick latest loader", NULL); // fetching banished to thread
	dispatch_async(loaderQ, ^{
		NSArray *refreshedPhotos = [FlickrFetcher stanfordPhotos]; //first create local variable to load in separate thread
		dispatch_async(dispatch_get_main_queue(), ^{
			self.photos = refreshedPhotos; // self.photos is UIKit: main queue,
			[self getPhotoTags];
			[self.refreshControl endRefreshing];
		});
	});
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
