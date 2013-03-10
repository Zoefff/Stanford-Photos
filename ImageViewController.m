//
//  ImageViewController.m
//  Shutterbug
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "ImageViewController.h"
#import "AttributedStringViewController.h"

@interface ImageViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleBarButtonItem; // title above scrollview
@property (strong, nonatomic) UIPopoverController *urlPopover;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation ImageViewController

#pragma mark - Bar Button stuff

	// the setter for the bar button item is split in two, becasue if the setter is called before viewDidLoad, the outlets will not have been set yet. This metod is therefore also called from viewDidLoad (similar to the setter for image)

- (void)handleSplitViewBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy]; // returns an arry of all items on the toolbar. Mutable to be able to make changes
	if (_splitViewBarButtonItem) [toolbarItems removeObject:_splitViewBarButtonItem]; // remove current button (if there is a current one)
    if (barButtonItem) [toolbarItems insertObject:barButtonItem atIndex:0]; //￼ put the bar button as the first/on the left of our existing toolbar
    self.toolbar.items = toolbarItems; // write back te array with the new items in it
    _splitViewBarButtonItem = barButtonItem;

}

- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem {
	if (_splitViewBarButtonItem != splitViewBarButtonItem) {	// if a new button is given to me, then set it
		[self handleSplitViewBarButtonItem:splitViewBarButtonItem];
	}
}

// returns whether the "Show URL" segue should be allowed to fire
// prohibits the segue if we don't have a URL set in us yet or
//  if a popover showing the URL is already visible

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"Show URL"]) {
        return (self.imageURL && !self.urlPopover.popoverVisible) ? YES : NO;
    } else {
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}

// uses an AttributedStringViewController to display the URL of the image we are currently displaying
// if being presented by a Popover segue, grab ahold of the popover so that we can avoid
//  putting it up multiple times (by prohibiting it in shouldPerformSegueWithIdentfier:sender:)

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show URL"]) {
        if ([segue.destinationViewController isKindOfClass:[AttributedStringViewController class]]) {
            AttributedStringViewController *asc = (AttributedStringViewController *)segue.destinationViewController;
            asc.text = [[NSAttributedString alloc] initWithString:[self.imageURL description]];
            if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                self.urlPopover = ((UIStoryboardPopoverSegue *)segue).popoverController;
            }
        }
    }
}

// sets the title of the titleBarButtonItem (if connected) to the passed title (passed in this case by the prepareForSegue method)

- (void)setTitle:(NSString *)title
{
    super.title = title;
    self.titleBarButtonItem.title = title;
}

- (void)setImageURL:(NSURL *)imageURL
{
    _imageURL = imageURL;
    [self resetImage];
}

-(BOOL)makeRoomInCache{
	NSFileManager *fileManager = [[NSFileManager alloc]init];
	NSURL *cacheDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask]lastObject]; //get cache directory
	NSArray *directoryContents = [fileManager contentsOfDirectoryAtURL:cacheDirectory includingPropertiesForKeys:@[NSURLContentAccessDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
	
	NSMutableArray *datePhotoAccessed =[[NSMutableArray alloc]init];
	for (NSURL *entry in directoryContents) {
		[datePhotoAccessed addObject:[entry resourceValuesForKeys:@[NSURLPathKey,NSURLContentAccessDateKey] error:nil]];
	}
	
	NSSortDescriptor *accessDateSortDescriptor = [[NSSortDescriptor alloc]initWithKey:NSURLContentAccessDateKey ascending:NO];
	[datePhotoAccessed sortUsingDescriptors:@[accessDateSortDescriptor]];
	NSLog(@"%@",datePhotoAccessed);
	NSURL *oldPhotoURL = [datePhotoAccessed lastObject][NSURLPathKey];
	NSLog(@"%@",oldPhotoURL);
	NSLog(@"%@",[oldPhotoURL path]);
	BOOL success = [fileManager removeItemAtURL:oldPhotoURL error:nil];
	return success;
}

- (void)resetImage
{
    if (self.scrollView) {
        self.scrollView.contentSize = CGSizeZero;
        self.imageView.image = nil;
		
		[self.spinner startAnimating];
		NSURL *imageURL = self.imageURL; //grab the URL before we send the fetch off to a different thread (no __, because only read only necessary in the thread)

        if (imageURL) {
			dispatch_queue_t imageFetchQ = dispatch_queue_create("image fetcher", NULL);
			dispatch_async(imageFetchQ, ^{
				NSString *fileName = [imageURL lastPathComponent];
				NSFileManager *fileManager = [[NSFileManager alloc]init];
				NSURL *cacheDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask]lastObject]; //get cache directory
				NSURL *cachedPhotoURL = [cacheDirectory URLByAppendingPathComponent:fileName]; //create path for a chached photo
				
				
				NSData *imageData;
				if ([fileManager fileExistsAtPath:[cachedPhotoURL path]]) { // if photo is stored in cache
					imageData = [[NSData alloc] initWithContentsOfURL:cachedPhotoURL]; // read from cache
				} else {
					[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
					imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL]; // else: download from web
					[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
					[imageData writeToURL:cachedPhotoURL atomically:TRUE]; // store in cache
					[self makeRoomInCache];
				}
				
				UIImage *image = [[UIImage alloc] initWithData:imageData]; // create image from data

					// check to make sure we are still interested in this image (might have touched away)
				if (self.imageURL == imageURL) {
						// dispatch back to main queue to do UIKit work
					dispatch_async(dispatch_get_main_queue(), ^{
						if (image) {
							self.scrollView.zoomScale = 1.0; //reset zoomScale
							self.scrollView.contentSize = image.size; //set size of canvas to the size of the image
							self.imageView.image = image;
							self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);  // where in the superview will the imageView be drawn
							[self setZoomLevel]; //fixed bug: zoomLevel can only be set once the image has been loaded and set
						}
						[self.spinner stopAnimating];
					});
				}
			});
		}
	}
}

- (UIImageView *)imageView
{
    if (!_imageView) _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    return _imageView;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

// sets the title of the titleBarButtonItem (if connected) to self.title
//  (just in case setTitle: was called before self.titleBarButtonItem outlet was loaded)

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.scrollView addSubview:self.imageView];
    self.scrollView.minimumZoomScale = 0.2;
    self.scrollView.maximumZoomScale = 5.0;
    self.scrollView.delegate = self;
    [self resetImage]; //need to reset image in case setter is called before viewDidLoad was called (that's when outlets are set)
    self.titleBarButtonItem.title = self.title;
	[self handleSplitViewBarButtonItem:self.splitViewBarButtonItem];
}

-(void)setZoomLevel{
	if (self.imageView.image) {
			// Width ratio compares the width of the viewing area with the width of the image
		float widthRatio = self.scrollView.bounds.size.width / self.imageView.image.size.width;
		
			// Height ratio compares the height of the viewing area with the height of the image
		float heightRatio = self.scrollView.bounds.size.height / self.imageView.image.size.height;
			// Update the zoom scale
		[self.scrollView setZoomScale:MAX(widthRatio, heightRatio) animated:TRUE];
		[self.scrollView flashScrollIndicators];
	}
}

	//With Autolayout, you have to do geometry-dependent in viewDidLayoutSubviews. viewDidLayoutSubviews is the method sent to you after constraints have been processed.
	//Note that while viewWillAppear: will get called only as you go (back) on screen ...
	//... viewDidLayoutSubviews is called every time self.view’s bounds changes (i.e. more often)

-(void)viewDidLayoutSubviews{
	[self setZoomLevel]; // reset zoomLevel when device has been rotated
}

@end
