//
//  StanfordFlickrPhotosTVC.m
//  Stanford Photos
//
//  Created by JML on 01/03/2013.
//  Copyright (c) 2013 -TDM-. All rights reserved.
//

#import "StanfordFlickrPhotosTVC.h"
#import "FlickrFetcher.h"

@interface StanfordFlickrPhotosTVC ()

@end

@implementation StanfordFlickrPhotosTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.photos = [FlickrFetcher stanfordPhotos];
}

@end
