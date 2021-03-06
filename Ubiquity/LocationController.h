//
//  LocationController.h
//  Ubiquity
//
//  Created by Ada Taylor on 7/29/13.
//  Copyright (c) 2013 Team Ubi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import <Parse/Parse.h>
#import "Geocoding.h"

// protocol for sending location updates to another view controller
@protocol LocationControllerDelegate
@required
- (void)locationUpdate:(CLLocation*)location;
@end

@interface LocationController : NSObject <CLLocationManagerDelegate> {
    
    CLLocationManager* locationManager;
    __weak id delegate;
    BOOL hasReceivedFirstUpdate;
    PFQuery *pushQuery;
}

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* location;

@property (nonatomic, strong) GMSMarker *marker;
@property (nonatomic, strong) GMSMapView *map;
@property (nonatomic, strong) GMSGeocoder *geocoder;
@property (nonatomic, strong) NSString *markerLatestAddress;

@property (nonatomic, strong) UIAlertView *av;

@property (nonatomic, weak) id  delegate;

+ (LocationController*)sharedLocationController;
- (void) updateLocation:(CLLocationCoordinate2D)currentCoordinate;

- (void) moveMarkerToLocation:(CLLocationCoordinate2D)newCoordinate;

- (void) sendForegroundLocationToServerForPushNotifications:(CLLocation *)location;

@end