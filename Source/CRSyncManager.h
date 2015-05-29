//
//  CRSyncManager.h
//  CarrotSDK
//
//  Created by Heiko Dreyer on 05/23/15.
//  Copyright (c) 2015 boxedfolder.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CRSyncManager;
@protocol CRSyncManagerDelegate <NSObject>

- (void)syncManager:(CRSyncManager *)syncManager didFailWithError:(NSError *)error;
- (void)syncManagerDidFinishSyncing:(CRSyncManager *)syncManager;

@end

@class CREventStorage, CRBeaconStorage;

@interface CRSyncManager : NSObject

///---------------------------------------------------------------------------------------
/// @name Lifecycle
///---------------------------------------------------------------------------------------

/**
 Init instance with storages.
 */
- (instancetype)initWithDelegate:(id<CRSyncManagerDelegate>)delegate
                    eventStorage:(CREventStorage*)eventStorage
                   beaconStorage:(CRBeaconStorage *)beaconStorage;

///---------------------------------------------------------------------------------------
/// @name Sync
///---------------------------------------------------------------------------------------

/**
 Starts the syncing process
 */
- (void)startSyncing;

/**
 Stops the syncing process
 */
- (void)stopSyncing;

@end
