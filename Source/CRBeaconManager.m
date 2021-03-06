/*
 * Carrot -  beacon content management (sdk)
 * Copyright (C) 2016 Heiko Dreyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <CoreBluetooth/CoreBluetooth.h>
#import "CRBeaconManager.h"
#import "CRBeaconManagerDelegate.h"
#import "CRDefines.h"
#import "CRBeaconCache.h"
#import "CRBeacon.h"
#import "CRBeaconStorage.h"
#import "CREventStorage.h"
#import "CRBeaconEventAggregator.h"
#import "CREventCoordinator.h"
#import "CRSyncManager.h"
#import "CRAnalyticsProvider.h"

@interface CRBeaconManager () <CLLocationManagerDelegate, CBCentralManagerDelegate, CRSyncManagerDelegate>

- (void)_setup;
- (NSString *)_stringForState:(CLRegionState)state;
- (void)_sendLocalNotificationsAndNotifyDelegateWithEvents:(NSArray<CRNotificationEvent *> *)notificationObjects
                                                    beacon:(CRBeacon *)beacon;
- (void)_notifyDelegateToPresentEvents:(NSArray<__kindof CREvent *> *)objects beacon:(CRBeacon *)beacon;
- (NSArray<CLBeaconRegion *> *)_regions;

- (void)_handleEnterBeacons:(NSArray<CRBeacon *> *)beacons;
- (void)_handleExitBeacons:(NSArray<CRBeacon *> *)beacons;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRBeaconManager {
    CLLocationManager *_locationManager;
    CBCentralManager *_bluetoothManager;
    NSArray<CLBeaconRegion *> *_regions;
    
    CRBeaconCache *_beaconCache;
    CRBeaconStorage *_beaconStorage;
    CREventStorage *_eventStorage;
    CRBeaconEventAggregator *_aggregator;
    CREventCoordinator *_eventCoordinator;
    CRSyncManager *_syncManager;
    CRAnalyticsProvider *_analyticsProvider;
    
    BOOL _fMonitoring;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Initialising

- (instancetype)initWithDelegate:(id<CRBeaconManagerDelegate>)delegate
                             url:(NSURL *)url
                          appKey:(NSString *)key
{
    self = [super init];
    if (self) {
        _fMonitoring = YES;
        _url = url;
        _appKey = key;
        _delegate = delegate;
        _monitoringIsActive = NO;
        _isSyncing = NO;
        [self _setup];
    }
    
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Monitoring

- (void)startMonitoringBeacons {
    CRLog("Start monitoring beacons.");
    _monitoringIsActive = YES;
    [self startSyncing];
}

- (void)stopMonitoringBeacons {
    CRLog("Stop monitoring beacons.");
    [[self _regions] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_locationManager stopMonitoringForRegion:obj];
        [_locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)obj];
    }];
    [_locationManager stopUpdatingLocation];
    _monitoringIsActive = NO;
    _fMonitoring = NO;
}

- (void)_startMonitoringBeacons {
    if (![self isRangingAvailable] || ![self isMonitoringAvailable]) {
        CRLog("No hardware support for ranging and monitoring.");
        _monitoringIsActive = NO;
        return;
    }
    
    // Stop ranging and monitoring beacons from previous sessions
    [_locationManager.rangedRegions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [_locationManager stopMonitoringForRegion:obj];
        [_locationManager stopRangingBeaconsInRegion:obj];
    }];
    
    [[self _regions] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CRLog("Start monitoring region: %@", obj);
        CLBeaconRegion *region = obj;
        region.notifyOnEntry = YES;
        region.notifyOnExit = YES;
        region.notifyEntryStateOnDisplay = YES;
        [_locationManager startRangingBeaconsInRegion:region];
        [_locationManager startMonitoringForRegion:region];
    }];
    [_locationManager startUpdatingLocation];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Status

- (BOOL)isAuthorized {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
}

- (BOOL)isRangingAvailable {
    return [CLLocationManager isRangingAvailable];
}

- (BOOL)isMonitoringAvailable {
    return [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]];
}

- (BOOL)locationServicesEnabled {
    return [CLLocationManager locationServicesEnabled];
}

- (BOOL)notificationsEnabled {
    UIUserNotificationSettings *settings = [UIApplication sharedApplication].currentUserNotificationSettings;
    return settings.types == (UIUserNotificationTypeAlert|UIUserNotificationTypeSound);
}

- (CRBluetoothState)bluetoothState {
    return (CRBluetoothState)_bluetoothManager.state;
}

- (void)grantNotficationPermission {
    UIApplication *application = [UIApplication sharedApplication];
    [application registerUserNotificationSettings:[UIUserNotificationSettings
                                                   settingsForTypes:
                                                   UIUserNotificationTypeAlert|UIUserNotificationTypeSound
                                                   categories:nil]];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Syncing & CRSyncManagerDelegate

- (void)startSyncing {
    CRLog("Start syncing process.");
    _isSyncing = YES;
    [_syncManager startSyncing];
}

- (void)stopSyncing {
    CRLog("Stop syncing process.");
    _isSyncing = NO;
    [_syncManager stopSyncing];
    if (_monitoringIsActive && _fMonitoring) {
        [self startMonitoringBeacons];
        _fMonitoring = NO;
    }
}

- (void)syncManager:(CRSyncManager *)syncManager didFailWithError:(NSError *)error {
    CRLog("Syncing process failed");
    _isSyncing = NO;
    _fMonitoring = NO;
    
    if (_monitoringIsActive) {
        [self _startMonitoringBeacons];
    }
    
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:syncingDidFailWithError:)]) {
        [_delegate manager:self syncingDidFailWithError:error];
    }
}

- (void)syncManagerDidFinishSyncing:(CRSyncManager *)syncManager {
    CRLog("Syncing process finished.");
    _isSyncing = NO;
    _fMonitoring = NO;
    
    if (_monitoringIsActive) {
        [self _startMonitoringBeacons];
    }
    
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(managerDidFinishSyncing:)]) {
        [_delegate managerDidFinishSyncing:self];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Private

- (void)_setup {
    _regions = [NSArray array];
    _beaconCache = [[CRBeaconCache alloc] init];
    
    _beaconStorage = [[CRBeaconStorage alloc] initWithStoragePath:CRBeaconDataBeaconFilePath];
    _aggregator = [[CRBeaconEventAggregator alloc] initWithStoragePath:CRBeaconDataAggregrationFilePath];
    _eventStorage = [[CREventStorage alloc] initWithBaseStoragePath:CRBeaconBaseDataPath aggregator:_aggregator];
    _eventCoordinator = [[CREventCoordinator alloc] initWithEventStorage:_eventStorage];
    
    _syncManager = [[CRSyncManager alloc] initWithDelegate:self
                                              eventStorage:_eventStorage
                                             beaconStorage:_beaconStorage
                                                aggregator:_aggregator
                                                   baseURL:_url
                                                    appKey:_appKey];
    _analyticsProvider = [[CRAnalyticsProvider alloc] initWithBaseURL:_url appKey:_appKey];
    
    _bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self
                                                             queue:dispatch_get_main_queue()
                                                           options:@{CBCentralManagerOptionShowPowerAlertKey: @NO}];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.pausesLocationUpdatesAutomatically = NO;
    
    // Important for iOS 8
    if([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationManager requestAlwaysAuthorization];
    }
    
    // Important for iOS 9
    if ([_locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]) {
        _locationManager.allowsBackgroundLocationUpdates = YES;
    }
}

- (NSString *)_stringForState:(CLRegionState)state {
    NSString *stateString;
    
    switch (state) {
        case CLRegionStateInside:
            stateString = @"CLRegionStateInside";
            break;
            
        case CLRegionStateOutside:
            stateString = @"CLRegionStateOutside";
            break;
            
        default:
            stateString = @"CLRegionStateUnknown";
            break;
    }
    
    return stateString;
}

- (NSArray<CLBeaconRegion *> *)_regions {
    return [_beaconStorage UUIDRegions];
}

- (void)_handleEnterBeacons:(NSArray<CRBeacon *> *)beacons {
    [beacons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CRBeacon *beacon = nil;
        if ([obj isKindOfClass:[CRBeacon class]]) {
            beacon = obj;
        }
        
        // Find concrete CRBeacon instance in storage
        // Only call delegate if a CRBeacon was found
        beacon = [_beaconStorage findCRBeaconWithUUID:beacon.uuid major:beacon.major minor:beacon.minor];
        beacon.beacon = ((CRBeacon *)obj).beacon;
        
        if (beacon) {
            if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didEnterBeaconRadius:)]) {
                [_delegate manager:self didEnterBeaconRadius:beacon];
            }
            
            // Check and perform notification handling if necessary.
            NSArray<CRNotificationEvent *> *notificationObjects = [_eventCoordinator validEnterNotificationEventsForBeacon:beacon];
            [self _sendLocalNotificationsAndNotifyDelegateWithEvents:notificationObjects beacon:beacon];
            
            // Check and perform event handling if necessary.
            NSArray<__kindof CREvent *> *objects = [_eventCoordinator validEnterEventsForBeacon:beacon];
            [self _notifyDelegateToPresentEvents:objects beacon:beacon];
        }
    }];
}

- (void)_handleExitBeacons:(NSArray<CRBeacon *> *)beacons {
    [beacons enumerateObjectsUsingBlock:^(CRBeacon * obj, NSUInteger idx, BOOL *stop) {
        CRBeacon *beacon = nil;
        if ([obj isKindOfClass:[CRBeacon class]]) {
            beacon = obj;
        }
        // Find concrete CRBeacon instance in storage
        // Only call delegate if a CRBeacon was foundon instance from storage
        beacon = [_beaconStorage findCRBeaconWithUUID:beacon.uuid major:beacon.major minor:beacon.minor];
        beacon.beacon = obj.beacon;
        
        if (beacon) {
            if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didExitBeaconRadius:)]) {
                [_delegate manager:self didExitBeaconRadius:beacon];
            }
            
            // Check and perform notification handling if necessary.
            NSArray<CRNotificationEvent *> *notificationObjects = [_eventCoordinator validExitNotificationEventsForBeacon:beacon];
            [self _sendLocalNotificationsAndNotifyDelegateWithEvents:notificationObjects beacon:beacon];
            
            // Check and perform event handling if necessary.
            NSArray<__kindof CREvent *> *objects = [_eventCoordinator validExitEventsForBeacon:beacon];
            [self _notifyDelegateToPresentEvents:objects beacon:beacon];
        }
    }];
}

- (void)_sendLocalNotificationsAndNotifyDelegateWithEvents:(NSArray<CRNotificationEvent *> *)notificationObjects
                                                    beacon:(CRBeacon *)beacon
{
    for (CRNotificationEvent *event in notificationObjects) {
        [_analyticsProvider logEvent:(CREvent *)event forBeacon:beacon];
        [_eventCoordinator sendLocalNotificationWithEvent:event];
        if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didFireNotification:beacon:)]) {
            [_delegate manager:self didFireNotification:event beacon:beacon];
        }
    }
}

- (void)_notifyDelegateToPresentEvents:(NSArray<CREvent *> *)objects beacon:(CRBeacon *)beacon {
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:shouldPresentEvents:beacon:)]) {
        if (objects && objects.count > 0) {
            [_analyticsProvider logEvents:objects forBeacon:beacon];
            [_delegate manager:self shouldPresentEvents:objects beacon:beacon];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region
{
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didRangeBeacons:inRegion:)]) {
        [_delegate manager:self didRangeBeacons:beacons inRegion:region];
    }

    // TODO: Problems?!
    NSArray<CRBeacon *> *enteredBeacons = [_beaconCache enteredCRBeaconsForRangedBeacons:beacons inRegion:region];
    NSArray<CRBeacon *> *exitedBeacons = [_beaconCache exitedCRBeaconsRangedBeacons:beacons inRegion:region];
    
    if (enteredBeacons.count > 0) {
        CRLog(@"Entered beacons: %@", enteredBeacons);
        [self _handleEnterBeacons:enteredBeacons];
    }
    
    if (exitedBeacons.count > 0) {
        CRLog(@"Exited beacons: %@", exitedBeacons);
        [self _handleExitBeacons:exitedBeacons];
    }
    
    [_beaconCache addCRBeaconsFromRangedBeacons:beacons forUUID:region.proximityUUID];
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    CRLog("Did determine state: %@ - Region: %@", [self _stringForState:state], region);
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didDetermineState:forRegion:)]) {
        [_delegate manager:self didDetermineState:state forRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    CRLog("Ranging beacons failed for region: %@ - Error: %@", region, error);
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:rangingBeaconsDidFailForRegion:withError:)]) {
        [_delegate manager:self rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    CRLog("Did enter region: %@", region);
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didEnterRegion:)]) {
        [_delegate manager:self didEnterRegion:(CLBeaconRegion *)region];
    }
    
    // Start ranging here
    [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
    [manager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{
    CRLog("Did exit region: %@", region);
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didExitRegion:)]) {
        [_delegate manager:self didExitRegion:(CLBeaconRegion *)region];
    }
    
    // Stop ranging here
    [manager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    CRLog("Did fail: %@", error);
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didFailWithError:)]) {
        [_delegate manager:self didFailWithError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error
{
    CRLog("Did fail for Region: %@ - Error: %@", region, error);
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:monitoringDidFailForRegion:withError:)]) {
        [_delegate manager:self monitoringDidFailForRegion:(CLBeaconRegion *)region withError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    CRLog("Did change authorization status: %d", status);
    
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didChangeAuthorizationStatus:)]) {
        [_delegate manager:self didChangeAuthorizationStatus:status];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    CRLog("Did update bluetooth state: %ld", (long)central.state);
    
    if ([(id<CRBeaconManagerDelegate>)_delegate respondsToSelector:@selector(manager:didUpdateBluetoothState:)]) {
        [_delegate manager:self didUpdateBluetoothState:(CRBluetoothState)central.state];
    }
}

@end
