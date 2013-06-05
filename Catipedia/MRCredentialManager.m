//
//  MRCredentialManager.m
//  Catipedia
//
//  Created by Gio on 05/06/2013.
//  Copyright (c) 2013 Memrise. All rights reserved.
//

#import "MRCredentialManager.h"

static NSString *kConfigJSONFileName = @"secret";
static NSString *kKeyKey = @"s3Key";
static NSString *kSecretKey = @"s3Secret";

@implementation MRCredentialManager

+ (NSString *)S3KeyID
{
    NSDictionary *dict = [MRCredentialManager dictionaryFromJSONNamed:kConfigJSONFileName];
    return [dict valueForKey:kKeyKey];
}

+ (NSString *)S3Secret
{
    NSDictionary *dict = [MRCredentialManager dictionaryFromJSONNamed:kConfigJSONFileName];
    return [dict valueForKey:kSecretKey];
}

+ (NSDictionary *)dictionaryFromJSONNamed:(NSString *)jsonName
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:jsonName ofType:@"json"];
    return [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:kNilOptions error:nil];
}

@end
