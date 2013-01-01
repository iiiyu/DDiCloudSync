//
//  DDiCloudSyncTests.m
//  DDiCloudSyncTests
//
//  Created by Dominik Pich on 01.01.13.
//  Copyright (c) 2013 Walt Disney Company. All rights reserved.
//

#import "DDiCloudSyncTests.h"

@implementation DDiCloudSyncTests

- (void)setUp
{
    [super setUp];
    [DDiCloudSync sharedSync].delegate = self;
    [[DDiCloudSync sharedSync] start];
}

- (void)tearDown
{
    [[DDiCloudSync sharedSync] stop];
    
    [super tearDown];
}

- (void)testSyncToICloud
{
    [DDiCloudSync sharedSync].lastSyncedDict = nil;
    [[NSUserDefaults standardUserDefaults] setObject:@"test" forKey:@"foo"];
    
    id dHave = [[DDiCloudSync sharedSync] lastSyncedDict][@"merged"];
    id dGoal = @"to icloud";
    STAssertEqualObjects(dHave, dGoal, @"The dictionary sync'd into the cloud is not what it should be");
}

- (void)testSyncFromICloud
{
    [DDiCloudSync sharedSync].lastSyncedDict = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:self];

    id dHave = [[DDiCloudSync sharedSync] lastSyncedDict][@"merged"];
    id dGoal = @"from icloud";
    STAssertEqualObjects(dHave, dGoal, @"The dictionary sync'd into from cloud into local defaults is not what it should be");
}

#pragma mark DDiCloudSyncDelegate

- (NSDictionary*)mergedDefaultsForUpdatingCloud:(NSDictionary*)dictInCloud withLocalDefaults:(NSDictionary*)dict {
    NSMutableDictionary *newdict = dict.mutableCopy;
    newdict[@"merged"] = @"to icloud";
    return newdict;
}

- (NSDictionary*)mergedDefaultsForUpdatingLocalDefaults:(NSDictionary*)dict withCloud:(NSDictionary*)dictInCloud {
    NSMutableDictionary *newdict = dict.mutableCopy;
    newdict[@"merged"] = @"from icloud";
    return newdict;
}

@end
