//
//  CRBeaconManager.h
//  CarrotSDK
//
//  Created by Heiko Dreyer on 05/23/15.
//  Copyright (c) 2015 boxedfolder.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol CRBeaconManagerDelegate;

@interface CRBeaconManager : NSObject

@property (nonatomic, assign) id <CRBeaconManagerDelegate> delegate;
@property (readonly) NSURL *url;
@property (readonly) NSString *appKey;

///---------------------------------------------------------------------------------------
/// @name Lifecycle
///---------------------------------------------------------------------------------------

/**
 Initialize a CRBeaconManager instance. Must provide a valid app key and url to corresponding bms.
 @see CRBeaconManagerDelegate
 */
-(instancetype)initWithDelegate: (id<CRBeaconManagerDelegate>)delegate
                            url: (NSURL *)url
                         appKey: (NSString *)key;

///---------------------------------------------------------------------------------------
/// @name Monitoring
///---------------------------------------------------------------------------------------

/**
 Handles all forms of authorization to allow Carrot to work. E.g. checking Bluetooth status, asking for permissions.
 */
-(void)handleAuthorization;

/**
 Start ranging beacons. Checking for proximity of available beacons.
 */
-(void)startRangingBeacons;

/**
 Stop ranging beacons. No further delegate methods are being called.
 */
-(void)stopRangingBeacons;

///---------------------------------------------------------------------------------------
/// @name Syncing
///---------------------------------------------------------------------------------------

/**
 Connect to CarrotBMS and start syncing beacons and events.
 */
-(BOOL)startSyncingProcessWithError: (NSError * __autoreleasing *)error;

/**
 Stop syncing beacon data.
 */
-(BOOL)cancelSyncingProcess;

@end
