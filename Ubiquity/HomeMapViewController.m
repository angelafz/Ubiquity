//
//  HomeMapViewController.m
//  Ubiquity
//
//  Created by Winnie Wu on 8/9/13.
//  Copyright (c) 2013 Team Ubi. All rights reserved.
//

#import "HomeMapViewController.h"
#import "HomeMapView.h"
#import "AppDelegate.h"
#import "NewMessageViewController.h"
#import "WallPostsViewController.h"
#import "OptionsViewController.h"
#import "NoteViewController.h"
#import "LocationController.h"
#import "TutorialViewController.h"
#import "GMSMarkerWithCount.h"
#import <math.h>
#import "Reachability.h"

#define kOFFSET_FOR_KEYBOARD 190.0


@interface HomeMapViewController ()
{
    CGFloat zoomLevel;
    BOOL idleMethodBeingCalled; // async lock for background query method to prevent more than 1 query happening at once
    
}

@property (nonatomic, strong) HomeMapView *hmv;
@property (nonatomic, strong) WallPostsViewController *wpvc;
@property (nonatomic, strong) UINavigationController *wallPostsNavController;

@property (nonatomic, strong) NSDictionary *markerNotearrayDict;
@end

@implementation HomeMapViewController
@synthesize gs;

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate firstLaunch]) {
        TutorialViewController *tutorial = [[TutorialViewController alloc] init];
        tutorial.delegate = self;
        self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:tutorial animated:YES completion:nil];
     }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayPins)
                                                 name:kPAWPostsUpdated
                                               object:nil];
}

- (void)viewDidLoad
{
    _hmv = [[HomeMapView alloc] initWithFrame: [UIScreen mainScreen].bounds];
    [self setView: _hmv];
    _hmv.map.delegate = self;
    zoomLevel = _hmv.map.camera.zoom;
    self.objects = [[NSMutableArray alloc] init];
    [self loadPins];
    
    _hmv.map.delegate = self;
    [_hmv.locationSearchButton addTarget:self action:@selector(startSearch:) forControlEvents:UIControlEventTouchUpInside];
    
    [_hmv.currentLocationButton addTarget:self action:@selector(returnToCurrentLocation:) forControlEvents:UIControlEventTouchUpInside];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshPins)
                                                 name:KPAWInitialLocationFound
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshMap)
                                                 name:kPAWLocationChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshPins)
                                                 name: kPAWPostCreatedNotification
                                               object:nil];
    
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error: No Internet Connection"
                                                          message:nil
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
    
    _hmv.tapRecognizer = [[UITapGestureRecognizer alloc]  initWithTarget:self action:@selector(hideKeyboard:)];
    [_hmv addGestureRecognizer:_hmv.tapRecognizer];
    
    if ([PFUser currentUser] != nil) {
        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"owner"];
        [[PFInstallation currentInstallation] saveInBackground];
    }
}


- (void) refreshPins
{
    [self loadPins];
}

- (void) refreshMap
{
    [self loadPins];
    LocationController* locationController = [LocationController sharedLocationController];
    [locationController updateLocation:locationController.location.coordinate];

    CLLocationCoordinate2D coords = locationController.marker.position;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:coords.latitude
                                                            longitude:coords.longitude
                                                                 zoom:_hmv.map.camera.zoom];

    _hmv.map.camera = camera;

}

- (void) returnToCurrentLocation: (id)sender
{
    LocationController* locationController = [LocationController sharedLocationController];
    
    CLLocationCoordinate2D currentCoordinate = locationController.location.coordinate;
    locationController.marker.position = currentCoordinate;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:currentCoordinate.latitude
                                                            longitude:currentCoordinate.longitude
                                                                 zoom:_hmv.map.camera.zoom];
    
    _hmv.map.camera = camera;

    
}

- (void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    [self performSelector:@selector (cluster) withObject:self afterDelay:0.25];
    
}

- (void) cluster
{
    if ([PFUser currentUser] != nil) {
        if (zoomLevel > _hmv.map.camera.zoom + 0.5 || zoomLevel < _hmv.map.camera.zoom - 0.5)
        {
            if (!idleMethodBeingCalled)
            {
                idleMethodBeingCalled = true;
                double newRange = 77.4795 * pow(M_E, -0.683106 * _hmv.map.camera.zoom);
                NSLog(@"%f new range", newRange);
                [AppDelegate makeParseQuery: self.segmentedControl.selectedSegmentIndex];
            }
        }
    }
}


- (void) loadPins
{
    if ([PFUser currentUser] != nil) {
        int type = self.segmentedControl.selectedSegmentIndex;
        
        [AppDelegate makeParseQuery: type];
        
        _hmv.map.delegate = self;
        _hmv.locationSearchTextField.delegate = self;
    }
}

- (void) displayPins {
    int type = self.segmentedControl.selectedSegmentIndex;
    
    if (type == 0) {
        [self displayParseQuery:[AppDelegate postsBySelf]];
    } else if (type == 1) {
        [self displayParseQuery:[AppDelegate postsByFriends]];
    } else {
        [self displayParseQuery:[AppDelegate postsByPublic]];
    }
}

- (BOOL)mapView:(GMSMapView*)mapView didTapMarker:(GMSMarker *)marker
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         marker.icon = [UIImage imageNamed:@"ReadNote"];
                     }];
    
    [self readNote: marker];
    return YES;
}


- (void) displayParseQuery: (NSMutableArray *) array
{
    double range = 116.21925 * pow(M_E, -0.683106 * _hmv.map.camera.zoom);
    
    [self.objects removeAllObjects];
    [_hmv.map clear];
    
    PFGeoPoint *current = [[PFGeoPoint alloc] init];
    NSMutableArray *allNotes = [[NSMutableArray alloc] init];
    NSMutableArray *notesForMarker = [[NSMutableArray alloc] init];
    NSMutableArray *markers = [[NSMutableArray alloc] init];
    GMSMarkerWithCount *marker = nil;
    
    for (PFObject *object in array) {
        NSLog(@"%@", object.objectId);
        PFGeoPoint *gp = [object objectForKey: @"location"];
        if (![self pointsAreEqualA:current andB:gp withinRange:range])
        {
            if (markers.count != 0)
                [allNotes addObject: [notesForMarker copy]];
            [notesForMarker removeAllObjects];
            CLLocationCoordinate2D pinLocation = CLLocationCoordinate2DMake (gp.latitude, gp.longitude);
            marker = [GMSMarkerWithCount markerWithPosition: pinLocation];
            [marker restartCount];
            marker.animated = YES;
            marker.map = _hmv.map;
            zoomLevel = _hmv.map.camera.zoom;
            
            NSLog(@"new pin!");
            
            [markers addObject: marker];
            self.markerNotearrayDict = [[NSMutableDictionary alloc] initWithObjects: @[markers, allNotes] forKeys:@[@"markers", @"arrayOfNotes"]];
        }
        
        PFObject *receipt = [AppDelegate postReceipt:object];
        NSDate *receivedAt = nil;
        receivedAt = [receipt objectForKey:@"dateOpened"];
        if(receivedAt == nil) {
           [marker updateIcon];
        }
        
        [notesForMarker addObject:object];
        
        current = gp;
    }
    [allNotes addObject: [notesForMarker copy]];
    idleMethodBeingCalled = false;
}

- (BOOL) pointsAreEqualA: (PFGeoPoint *) p1 andB: (PFGeoPoint *) p2 withinRange: (double) d
{

    // still not clumping in midrange for some obscure reason
    
   // double distance = [p1 distanceInKilometersTo:p2]/111;
   // return (distance > d);
    return (p1.latitude + d >= p2.latitude && p1.latitude - d <= p2.latitude && p1.longitude + d >= p2.longitude && p1.longitude - d <= p2.longitude);
}


- (void)initButtons
{
    UIBarButtonItem *mapList = [[UIBarButtonItem alloc] initWithTitle:@"< List"
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(launchPostsView)];
    [[self navigationItem] setLeftBarButtonItem:mapList];
    
    UIImage *image = [UIImage imageNamed:@"newMessage"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage: [image stretchableImageWithLeftCapWidth:7.0 topCapHeight:0.0] forState:UIControlStateNormal];
    button.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    [button addTarget:self action:@selector(launchNewMessage)    forControlEvents:UIControlEventTouchUpInside];
    
    UIView *v= [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, image.size.width, image.size.height) ];
    [v addSubview:button];
    
    UIBarButtonItem *newMessage = [[UIBarButtonItem alloc] initWithCustomView:v];
    self.navigationItem.rightBarButtonItem = newMessage;
    
}

- (void)launchNewMessage
{
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error: No Internet Connection"
                                                          message:@"Can't send messages when offline."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    } else {
        NewMessageViewController *nmvc = [[NewMessageViewController alloc] init];
        UINavigationController *newMessageNavController = [[UINavigationController alloc]
                                                           initWithRootViewController:nmvc];
        self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:newMessageNavController animated:YES completion:nil];
        
        nmvc.view.frame = CGRectMake(nmvc.view.frame.origin.x, self.view.frame.size.height, nmvc.view.frame.size.width, nmvc.view.frame.size.height);
        [UIView animateWithDuration:0.25
                         animations:^{
                             nmvc.view.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height, nmvc.view.frame.size.width, nmvc.self.view.frame.size.height);
                         }];
    }
}

- (void) readNote: (id) sender
{
    GMSMarker *marker = sender;
    NSArray *notesList = [self getNotesListForMarker:marker];
    if (notesList)
    {
        NSLog(@"%@", notesList);
        NoteViewController *nvc = [[NoteViewController alloc] init];
        nvc.notes = notesList;
        UINavigationController *noteViewNavController = [[UINavigationController alloc]
                                                         initWithRootViewController:nvc];
        self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:noteViewNavController animated:YES completion:nil];
        
        nvc.view.frame = CGRectMake(nvc.view.frame.origin.x, self.view.frame.size.height, nvc.view.frame.size.width, nvc.view.frame.size.height);
        [UIView animateWithDuration:0.25
                         animations:^{
                             nvc.view.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height, nvc.view.frame.size.width, nvc.self.view.frame.size.height);
                         }];
    }
}

- (NSArray *) getNotesListForMarker: (GMSMarker *) marker
{
    NSArray *markersArray = [self.markerNotearrayDict objectForKey:@"markers"];
    for (int i = 0; i<markersArray.count; i++)
    {
        if ([markersArray[i] isEqual: marker])
        {
            return [self.markerNotearrayDict objectForKey:@"arrayOfNotes"][i];
        }
        
    }
    return nil;
}

- (id)init{
    self = [super init];
    if (self) {
        [self initButtons];
        [self initSegmentedControl];
        [self initOptionsButton];
    }
    return self;
}

- (void)initSegmentedControl
{
    NSArray *itemArray = [NSArray arrayWithObjects: [UIImage imageNamed:@"me"], [UIImage imageNamed:@"friends"], [UIImage imageNamed:@"public"], nil];
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    self.segmentedControl.frame = CGRectMake(0,0,150,35);
    self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [self.segmentedControl setSelectedSegmentIndex:0];
    [self.segmentedControl addTarget:self
                              action:@selector(changeSegment:)
                    forControlEvents:UIControlEventValueChanged];
    [[self navigationItem] setTitleView:self.segmentedControl];
}

- (void)changeSegment:(UISegmentedControl *)sender
{
    NSInteger value = [sender selectedSegmentIndex];
    [self loadPins];
}


- (void)launchPostsView
{
    LocationController *locController = [LocationController sharedLocationController];
    if ((locController.location.coordinate.latitude == 0) && (locController.location.coordinate.longitude == 0)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Turn On Location Services to See Nearby Posts"
                                                          message:@"Please go to Settings -> Privacy -> Location Services to turn it on."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
    
    
    if(_wpvc == nil) {
        _wpvc = [[WallPostsViewController alloc] init];
        _wallPostsNavController = [[UINavigationController alloc]
                                   initWithRootViewController:_wpvc];
    }
    _wallPostsNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self.navigationController presentViewController:_wallPostsNavController animated:YES completion:nil];
    
}




- (void)initOptionsButton
{
    int const SCREEN_WIDTH = self.view.frame.size.width;
    int const SCREEN_HEIGHT = self.view.frame.size.height;
    self.optionsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *pictureButtonImage = [UIImage imageNamed:@"gear"];
    [self.optionsButton setBackgroundImage:pictureButtonImage forState:UIControlStateNormal];
    self.optionsButton.frame = CGRectMake(SCREEN_WIDTH - 25, SCREEN_HEIGHT - 70, 20.0, 20.0);
    [self.optionsButton addTarget:self action:@selector(launchOptionsMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.optionsButton];
}

- (void)launchOptionsMenu
{
    OptionsViewController *ovc = [[OptionsViewController alloc] init];
    UINavigationController *optionsNavController = [[UINavigationController alloc] initWithRootViewController:ovc];    
    self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:optionsNavController animated:YES completion:nil];
    
    ovc.view.frame = CGRectMake(ovc.view.frame.origin.x, self.view.frame.size.height, ovc.view.frame.size.width, ovc.view.frame.size.height);
    [UIView animateWithDuration:0.25
                     animations:^{
                         ovc.view.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height, ovc.view.frame.size.width, ovc.self.view.frame.size.height);
                     }];
    
}

-(void) mapView:(GMSMapView *)mv didLongPressAtCoordinate:(CLLocationCoordinate2D)coord
{
    LocationController *locationController = [LocationController sharedLocationController];
    [locationController moveMarkerToLocation:coord];
}


-(void)textFieldDidBeginEditing:(UITextField*)sender
{
    [_hmv.map setUserInteractionEnabled:NO];
}


- (void) startSearch: (id) sender
{
    LocationController* locationController = [LocationController sharedLocationController];
    CLLocationCoordinate2D currentCoordinate = locationController.location.coordinate;
    NSDictionary *curLocation = [[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithDouble:currentCoordinate.latitude],@"lat",[NSNumber numberWithDouble:currentCoordinate.longitude],@"lng",@"",@"address",nil];
    //Not a perfect solution for keeping the map at the same place
    //TODO: Fix it so map doesn't shift at all when search for invalid address
    gs = [[Geocoding alloc] initWithCurLocation:curLocation];
    [gs geocodeAddress:_hmv.locationSearchTextField.text withCallback:@selector(addMarker) withDelegate:self];
}

- (void)addMarker{
    
    double lat = [[gs.geocode objectForKey:@"lat"] doubleValue];
    double lng = [[gs.geocode objectForKey:@"lng"] doubleValue];
    
    GMSMarker *marker = [[GMSMarker alloc] init];
    CLLocationCoordinate2D geolocation = CLLocationCoordinate2DMake(lat,lng);
    marker.position = geolocation;
    marker.title = [gs.geocode objectForKey:@"address"];
    
    //marker.map = _hmv.map;
    [LocationController sharedLocationController].marker.position = geolocation;
    
    GMSCameraUpdate *geoLocateCam = [GMSCameraUpdate setTarget:geolocation];
    [_hmv.map animateWithCameraUpdate:geoLocateCam];
    
}

-(void) hideKeyboard: (id) sender
{
    [_hmv.locationSearchTextField resignFirstResponder];
    [_hmv.map setUserInteractionEnabled:YES];
}

@end
