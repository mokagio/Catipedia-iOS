//
//  MRCredentialManager.h
//  Catipedia
//
//  Created by Gio on 05/06/2013.
//  Copyright (c) 2013 Memrise. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MRCredentialManager : NSObject

+ (NSString *)S3APIKey;
+ (NSString *)S3Secret;

@end
