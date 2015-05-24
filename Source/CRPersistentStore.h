//
//  CRPersistentStore.h
//  CarrotSDK
//
//  Created by Heiko Dreyer on 05/24/15.
//  Copyright (c) 2015 boxedfolder.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `CRPersistentStore` is a class to store (serialize) abstract objects to disk.
 This class may be overriden for more concrete implementations
 Have a look at `CRDefinitions.h` for more information on storage paths.
 */
@interface CRPersistentStore : NSObject {
@protected
    NSMutableArray *_objects;
}

///---------------------------------------------------------------------------------------
/// @name Storage properties
///---------------------------------------------------------------------------------------

/**
 Storage path
 */
@property (readonly, strong) NSString *storagePath;

///---------------------------------------------------------------------------------------
/// @name Lifecycle
///---------------------------------------------------------------------------------------

/**
 Inits a Storage with given path.
 */
- (id)initWithStoragePath:(NSString *)path;

///---------------------------------------------------------------------------------------
/// @name Adding, deleting & retrieving objects
///---------------------------------------------------------------------------------------

/**
 Adds an object to store. The store usually auto-saves.
 
 @param object The object
 */
- (void)addObject:(id)object;

/**
 Remove an object from store. The store usually auto-saves.
 
 @param object The object
 */
- (void)removeObject:(id)object;

/**
 Return all stored objects.
 */
- (NSArray *)objects;

/**
 Adds an array to store.
 
 @param array An array
 */
- (void)addObjectsFromArray:(NSArray *)array;

/**
 Removes an array from store.
 
 @param array An array
 */
- (void)removeObjectsInArray:(NSArray *)array;

@end
