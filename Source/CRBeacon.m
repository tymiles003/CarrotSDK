//
//  CRBeacon.m
//  CarrotSDK
//
//  Created by Heiko Dreyer on 05/23/15.
//  Copyright (c) 2015 boxedfolder.com. All rights reserved.
//

#import "CRBeacon.h"

@implementation CRBeacon {
}

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Initialising

- (instancetype)initWithUUID:(NSUUID *)uuid
                       major:(NSNumber *)major
                       minor:(NSNumber *)minor
                        name:(NSString *)name
{
    self = [super init];
    
    if (self) {
        _name = name;
        _uuid = uuid;
        _major = major;
        _minor = minor;
        _beacon = nil;
    }
    
    return self;
}


- (instancetype)initWithUUID:(NSUUID *)uuid
                       major:(NSNumber *)major
                       minor:(NSNumber *)minor {
    return [self initWithUUID:uuid major:major minor:minor name:nil];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self initWithUUID:[coder decodeObjectOfClass:[NSString class] forKey:@"uuid"]
                        major:[coder decodeObjectOfClass:[NSString class] forKey:@"major"]
                        minor:[coder decodeObjectOfClass:[NSString class] forKey:@"minor"]
                         name:[coder decodeObjectOfClass:[NSString class] forKey:@"name"]];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_uuid forKey:@"uuid"];
    [aCoder encodeObject:_major forKey:@"major"];
    [aCoder encodeObject:_minor forKey:@"minor"];
    [aCoder encodeObject:_name forKey:@"name"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    CRBeacon *aObject = (CRBeacon *)object;
    if (!object ||
        ![aObject.uuid isEqual:self.uuid] ||
        ![aObject.major isEqualToNumber:self.major] ||
        ![aObject.minor isEqualToNumber:self.minor]
        )
    {
        return NO;
    }
    
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CRBeacon - UUID: %@ - Major: %@ - Minor: %@", _uuid, _major, _minor];
}

@end
