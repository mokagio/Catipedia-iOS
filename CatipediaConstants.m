//
//  CatipediaConstants.m
//  Catipedia
//
//  Created by Gio on 08/06/2013.
//  Copyright (c) 2013 Memrise. All rights reserved.
//

#import "CatipediaConstants.h"

@implementation CatipediaConstants

NSString *kBaseURL = @"http://catipedia-server.herokuapp.com";
//NSString *kBaseURL = @"http://localhost:5000";

NSString *kCatsListURL = @"http://catipedia-server.herokuapp.com/cats/";
//NSString *kCatsListURL = @"http://localhost:5000/cats/";

NSString *kCatsJSONKey = @"entries";
NSString *kCatWordKey = @"name";
NSString *kCatPictureURLKey = @"link";

NSString *kStorageBaseURL = @"https://s3.amazonaws.com/catipedia.memrise.com/";
NSString *kBucket = @"catipedia.memrise.com";

NSString *kCatsAddEndPoint = @"/cats/new/";


@end
