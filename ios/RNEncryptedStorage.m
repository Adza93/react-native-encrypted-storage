//
//  RNEncryptedStorage.m
//  Starter
//
//  Created by Yanick Bélanger on 2020-02-09.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import "RNEncryptedStorage.h"
#import <Security/Security.h>
#import <React/RCTLog.h>

void rejectPromise(NSString *message, NSError *error, RCTPromiseRejectBlock rejecter)
{
    NSString* errorCode = [NSString stringWithFormat:@"%ld", error.code];
    NSString* errorMessage = [NSString stringWithFormat:@"RNEncryptedStorageError: %@", message];

    rejecter(errorCode, errorMessage, error);
}

@implementation RNEncryptedStorage

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setItem:(NSString *)key withValue:(NSString *)value resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSData* dataFromValue = [value dataUsingEncoding:NSUTF8StringEncoding];
    
    if (dataFromValue == nil) {
        NSError* error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo: nil];
        rejectPromise(@"An error occured while parsing value", error, reject);
        return;
    }
    
    // Prepares the insert query structure
    NSDictionary* storeQuery = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : key,
        (__bridge id)kSecValueData : dataFromValue
    };
    
    // Deletes the existing item prior to inserting the new one
    SecItemDelete((__bridge CFDictionaryRef)storeQuery);
    
    OSStatus insertStatus = SecItemAdd((__bridge CFDictionaryRef)storeQuery, nil);
    
    if (insertStatus == noErr) {
        resolve(value);
    }
    
    else {
        NSError* error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:insertStatus userInfo: nil];
        rejectPromise(@"An error occured while saving value", error, reject);   
    }
}

RCT_EXPORT_METHOD(getItem:(NSString *)key resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSDictionary* getQuery = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : key,
        (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
        (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne
    };
    
    CFTypeRef dataRef = NULL;
    OSStatus getStatus = SecItemCopyMatching((__bridge CFDictionaryRef)getQuery, &dataRef);
    
    if (getStatus == errSecSuccess) {
        NSString* storedValue = [[NSString alloc] initWithData: (__bridge NSData*)dataRef encoding: NSUTF8StringEncoding];
        resolve(storedValue);
    }

    else if (getStatus == errSecItemNotFound) {
        resolve(nil);
    }
    
    else {
        NSError* error = [NSError errorWithDomain: [[NSBundle mainBundle] bundleIdentifier] code:getStatus userInfo:nil];
        rejectPromise(@"An error occured while retrieving value", error, reject);
    }
}

RCT_EXPORT_METHOD(getAllKeys:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSMutableArray* finalResult = [[NSMutableArray alloc] init];
    NSMutableDictionary* getQuery = [NSMutableDictionary dictionaryWithDictionary:@{
            (__bridge NSString *)kSecClass: (__bridge id)(kSecClassGenericPassword),
            (__bridge NSString *)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
            (__bridge NSString *)kSecMatchLimit: (__bridge NSString *)kSecMatchLimitAll,
            (__bridge NSString *)kSecReturnData: (__bridge id)kCFBooleanTrue
                                                                                }];
    
    CFTypeRef dataRef = NULL;
    OSStatus getStatus = SecItemCopyMatching((__bridge CFDictionaryRef)getQuery, &dataRef);
    
    if (getStatus == errSecSuccess) {
    
        if(dataRef != NULL){
            for (NSDictionary* item in (__bridge id)dataRef) {
                      [finalResult addObject:(NSString*)[item objectForKey:(__bridge id)(kSecAttrAccount)]];
                  }
        }
        resolve(finalResult);
    }

    else if (getStatus == errSecItemNotFound) {
        resolve(nil);
    }
    
    else {
        NSError* error = [NSError errorWithDomain: [[NSBundle mainBundle] bundleIdentifier] code:getStatus userInfo:nil];
        rejectPromise(@"An error occured while retrieving value", error, reject);
    }
}

RCT_EXPORT_METHOD(getAllKeysAndValues:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSMutableDictionary* query = [NSMutableDictionary dictionaryWithDictionary:@{
         (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
         (__bridge id)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
         (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll
     }];
     
     CFTypeRef result = NULL;
     OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
     
     if (status != errSecSuccess) {
         NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
         reject(@"KEYCHAIN_ERROR", @"Failed to retrieve items from the Keychain.", error);
         return;
     }
     
     NSArray *items = (__bridge_transfer NSArray *)result;
     NSMutableDictionary *keyValuePairs = [NSMutableDictionary dictionary];
     
     for (NSDictionary *item in items) {
         NSString *key = item[(__bridge id)kSecAttrAccount];
         NSData *valueData = item[(__bridge id)kSecValueData];
         NSString *value = [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
         
         if (key && value) {
             keyValuePairs[key] = value;
         }
     }
     
     resolve(keyValuePairs);
}

RCT_EXPORT_METHOD(save:(NSString *)secureStorageData resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSError *err;
    NSDictionary *arr =
     [NSJSONSerialization JSONObjectWithData:[secureStorageData dataUsingEncoding:NSUTF8StringEncoding]
                                     options:NSJSONReadingMutableContainers
                                       error:&err];
    
    NSArray *keys = [arr allKeys];
    NSArray *values = [arr allValues];
    int numberOfInsertedKeys = 0;
   //Iterate trough keypairs
    
    for(int i=0;i<[keys count];i++){
        //NSLog(@"%@", keys[i]);
        //NSLog(@"%@", values[i]);
        
        NSData* dataFromValue = [values[i] dataUsingEncoding:NSUTF8StringEncoding];
        
        if (dataFromValue == nil) {
            NSError* error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo: nil];
            rejectPromise(@"An error occured while parsing value", error, reject);
            return;
        }
        
        // Prepares the insert query structure
        NSDictionary* storeQuery = @{
            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrAccount : keys[i],
            (__bridge id)kSecValueData : dataFromValue
        };
        
        // Deletes the existing item prior to inserting the new one
        SecItemDelete((__bridge CFDictionaryRef)storeQuery);
        
        OSStatus insertStatus = SecItemAdd((__bridge CFDictionaryRef)storeQuery, nil);
        
        if (insertStatus == noErr) {
         //All good continue on
            numberOfInsertedKeys++;
        }
        else{
            NSError* error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:insertStatus userInfo: nil];
            rejectPromise(@"An error occured while saving value", error, reject);
            break;
        }
    }
    
    //Last check
    if (numberOfInsertedKeys == [keys count]) {
        resolve(@"true");
    }
    else {
        rejectPromise(@"An error occured while save()", nil, reject);
    }
}

RCT_EXPORT_METHOD(removeItem:(NSString *)key resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSDictionary* removeQuery = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : key,
        (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue
    };
    
    OSStatus removeStatus = SecItemDelete((__bridge CFDictionaryRef)removeQuery);
    
    if (removeStatus == noErr) {
        resolve(key);
    }
    
    else {
        NSError* error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:removeStatus userInfo: nil];
        rejectPromise(@"An error occured while removing value", error, reject);
    }
}

RCT_EXPORT_METHOD(clear:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSArray *secItemClasses = @[
        (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecClassInternetPassword,
        (__bridge id)kSecClassCertificate,
        (__bridge id)kSecClassKey,
        (__bridge id)kSecClassIdentity
    ];
    
    // Maps through all Keychain classes and deletes all items that match
    for (id secItemClass in secItemClasses) {
        NSDictionary *spec = @{(__bridge id)kSecClass: secItemClass};
        SecItemDelete((__bridge CFDictionaryRef)spec);
    }
    
    resolve(nil);
}
@end
