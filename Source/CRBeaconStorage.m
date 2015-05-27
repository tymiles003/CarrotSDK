//
//  CRBeaconStorage.m
//  CarrotSDK
//
//  Created by Heiko Dreyer on 05/24/15.
//  Copyright (c) 2015 boxedfolder.com. All rights reserved.
//

#import "CRBeaconStorage.h"
#import "CRBeacon.h"

@implementation CRBeaconStorage

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Beacon specific CRUD methods

- (CRBeacon *)findCRBeaconWithUUID: (NSUUID *)uuid major:(NSNumber *)major minor:(NSNumber *)minor {
    CRBeacon *beacon = [[CRBeacon alloc] initWithUUID:uuid major:major minor:minor];
    CRBeacon *result = beacon;
    /*
    CRBeacon *result = nil;
    
    NSArray *objects = [self objects];
    for (CRBeacon *aBeacon in objects) {
        if ([aBeacon isEqual:beacon]) {
            result = aBeacon;
            break;
        }
    }*/
    
    return result;
}

- (NSArray *)UUIDRegions {
    NSMutableSet *uuids = [NSMutableSet set];
    NSArray *objects = [self objects];
    for (CRBeacon *aBeacon in objects) {
        [uuids addObject:aBeacon.uuid];
    }
    
    return [uuids allObjects];
}

@end
