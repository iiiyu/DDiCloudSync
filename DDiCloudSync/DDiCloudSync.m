//
//  DDiCloudSync.h
//
//  Created by Dominik R. Pich, based on code by Mugunth Kumar (@mugunthkumar) on 1/1/13.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "DDiCloudSync.h"

NSString *kDDiCloudDidSyncNotification = @"DDiCloudSyncDidUpdateToLatest";

@implementation DDiCloudSync

- (void)updateToiCloud:(NSNotification*) notificationObject {
    NSUbiquitousKeyValueStore *iCloudStore = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *dictInCloud = [iCloudStore dictionaryRepresentation];
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    
    if(self.delegate) {
        dict = [self.delegate mergedDefaultsForUpdatingCloud:dictInCloud withLocalDefaults:dict];
    }
    
    //set up store
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [[NSUbiquitousKeyValueStore defaultStore] setObject:obj forKey:key];
    }];
    
    //sync
    self.lastSyncedDict = dict;
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)updateFromiCloud:(NSNotification*) notificationObject {
    NSUbiquitousKeyValueStore *iCloudStore = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *dictInCloud = [iCloudStore dictionaryRepresentation];
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    
    if(self.delegate) {
        dict = [self.delegate mergedDefaultsForUpdatingLocalDefaults:dict withCloud:dictInCloud];
    }
    
    // prevent NSUserDefaultsDidChangeNotification from being posted while we update from iCloud
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];
    
    //update defaults
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
    }];
    
    //sync to disk
    self.lastSyncedDict = dict;
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // enable NSUserDefaultsDidChangeNotification notifications again
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateToiCloud:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDiCloudDidSyncNotification object:nil];
}

#pragma mark -

- (void)start {
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"ignore icloud support checking for simulator");
#else
    // is iOS 5?
    if(NSClassFromString(@"NSUbiquitousKeyValueStore")) {
        // is iCloud enabled
        if([NSUbiquitousKeyValueStore defaultStore]) {
#endif
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(updateFromiCloud:)
                                                         name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(updateToiCloud:)
                                                         name:NSUserDefaultsDidChangeNotification                                                    object:nil];
            // start now first sync iCloud because NSUbiquitousKeyValueStoreDidChangeExternallyNotification
            // no frist time is send
            [self updateFromiCloud:nil];
            
#if TARGET_IPHONE_SIMULATOR
#else
        } else {
            NSLog(@"iCloud not enabled");
        }
    }
    else {
        NSLog(@"Not an iOS 5 device");
    }
#endif
}

- (void)stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) dealloc {
    [self stop];
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

#pragma mark -

+ (DDiCloudSync *)sharedSync {
    static DDiCloudSync *_sharedSync = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSync = [[[self class] alloc] init];
    });
    return _sharedSync;
}
@end
