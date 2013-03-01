//
//  RecentPhotoTVC.m
//  Stanford Photos
//
//  Created by JML on 01/03/2013.
//  Copyright (c) 2013 -TDM-. All rights reserved.
//

#import "RecentPhotoTVC.h"

#define RECENT_PHOTOS_KEY @"Recent Photo"

@interface RecentPhotoTVC ()

@end

@implementation RecentPhotoTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *recentPhotos = [defaults objectForKey:RECENT_PHOTOS_KEY];
	self.photos = recentPhotos;
}

@end
