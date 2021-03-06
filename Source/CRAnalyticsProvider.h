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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CREvent;
@class CRBeacon;

@interface CRAnalyticsProvider : NSObject

///---------------------------------------------------------------------------------------
/// @name Analytics
///---------------------------------------------------------------------------------------

/**
 Inits with a base url to bms
*/
- (instancetype)initWithBaseURL:(NSURL *)url appKey:(NSString *)appKey;

///---------------------------------------------------------------------------------------
/// @name Analytics
///---------------------------------------------------------------------------------------

/**
 The base url to bms
*/
@property (readonly, strong) NSURL *baseURL;

/**
 The app key
 */
@property (readonly, strong) NSString *appKey;

- (void)logEvent:(CREvent *)event forBeacon:(CRBeacon *)beacon;

- (void)logEvents:(NSArray *)events forBeacon:(CRBeacon *)beacon;

@end

NS_ASSUME_NONNULL_END