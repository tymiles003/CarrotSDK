//
//  CRRegionCache.m
//  CarrotSDK
//
//  Created by Heiko Dreyer on 05/26/15.
//  Copyright (c) 2015 boxedfolder.com. All rights reserved.
//

#import "CRBeaconCache.h"
#import "CRBeacon.h"

@interface CRBeaconCache()

-(NSArray *)_CRBeaconArrayFromBeaconArray:(NSArray *)beacons;

@end

@implementation CRBeaconCache

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Storing, Caching and general fiddling

- (void)addCRBeacons:(NSArray *)beacons forUUIDString:(NSString *)uuidString {
    [self setObject:[NSArray arrayWithArray:[self _CRBeaconArrayFromBeaconArray:beacons]] forKey:uuidString];
}

- (NSArray *)CRbeaconsForUUIDString:(NSString *)uuidString {
    NSArray *object = [self objectForKey:uuidString];
    if (!object) {
        object = [NSArray array];
    }
    return [NSArray arrayWithArray:object];
}

- (NSArray *)enteredCRBeaconsForRangedBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    NSArray *beaconsInRange = [self _CRBeaconArrayFromBeaconArray:beacons];
    NSArray *prevBeaconsInRange = [NSArray arrayWithArray:[self CRbeaconsForUUIDString:region.proximityUUID.UUIDString]];

    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", prevBeaconsInRange];
    return [beaconsInRange filteredArrayUsingPredicate:predicate];
}

- (NSArray *)exitedCRBeaconsRangedBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    NSArray *beaconsInRange = [self _CRBeaconArrayFromBeaconArray:beacons];
    NSArray *prevBeaconsInRange = [NSArray arrayWithArray:[self CRbeaconsForUUIDString:region.proximityUUID.UUIDString]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", beaconsInRange];
    return [prevBeaconsInRange filteredArrayUsingPredicate:predicate];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Private

-(NSArray *)_CRBeaconArrayFromBeaconArray:(NSArray *)beacons {
    NSMutableArray *crBeaconArray = [NSMutableArray array];
    for (CLBeacon *beacon in beacons) {
        CRBeacon *crBeacon = [[CRBeacon alloc] initWithUUID:beacon.proximityUUID.UUIDString
                                                      major:beacon.major
                                                      minor:beacon.minor];
        crBeacon.beacon = beacon;
        [crBeaconArray addObject:crBeacon];
    }
    
    return crBeaconArray;
}


@end