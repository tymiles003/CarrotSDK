//
//  CRPersistentRequestQueue.m
//  CarrotSDK
//
//  Created by Heiko Dreyer on 7/11/13
//  Copyright (c) 2015 boxedfolder.com. All rights reserved.
//

#import "CRPersistentRequestQueue.h"
#import "CRDefines.h"

@interface CRPersistentRequestQueue ()

- (void)_save;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRPersistentRequestQueue {
    NSString *_path;
    NSMutableArray *_queue;
    NSOperationQueue *_internalOperationQueue;
    NSOperationQueue *_storageQueue;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Initialising

- (id)initWithStoragePath:(NSString *)path {
    self = [super init];
    
    if (self) {
        _path = path;
        _internalOperationQueue = [[NSOperationQueue alloc] init];
        _internalOperationQueue.maxConcurrentOperationCount = 1;
        _storageQueue = [[NSOperationQueue alloc] init];
        _storageQueue.maxConcurrentOperationCount = 1;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        @try {
            if ([fileManager fileExistsAtPath:_path]) {
                _queue = [NSKeyedUnarchiver unarchiveObjectWithFile:_path];
            }
        } @finally {
            if (!_queue) {
                _queue = [NSMutableArray array];
            }
        }
    }
    
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Manage store

- (void)addRequest:(NSURLRequest *)request {
    [_queue addObject:request];
    [self _save];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (void)removeRequest:(NSURLRequest *)request {
    if ([_queue containsObject:request]) {
        [_queue removeObject:request];
        [self _save];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (void)removeLastRequest {
    [_queue removeLastObject];
    [self _save];
}

//////////////////////////////////////////////////////////////////////////////////////////////////

- (void)sendQueuedRequestsWithBlock:(void(^)(NSOperationQueue *queue, NSURLRequest *request))block {
    if (_queue.count == 0) {
        return;
    }
    // Copy all (currently stored) requests into a new array
    NSArray *queueCopy = [NSArray arrayWithArray:_queue];
    [queueCopy enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(_internalOperationQueue, obj);
        [_queue removeObject:obj];
    }];
    [self _save];
}

//////////////////////////////////////////////////////////////////////////////////////////////////

- (void)cancelQueuedRequests {
    [_internalOperationQueue cancelAllOperations];
    [_queue removeAllObjects];
    [self _save];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (void)waitUntilAllRequestsAreFinished {
    [_internalOperationQueue waitUntilAllOperationsAreFinished];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Internal

- (void)_save {
    [_storageQueue addOperationWithBlock:^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *dirpath = [_path stringByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:dirpath]) {
            [fileManager createDirectoryAtPath:dirpath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        [NSKeyedArchiver archiveRootObject:_queue toFile:_path];
    }];
}

@end
