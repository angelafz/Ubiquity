//

#import "LoginViewController.h"
#import "UserDetailsViewController.h"
#import <Parse/Parse.h>
#import "RecentViewController.h"
#import "AppDelegate.h"
#import "LoginView.h"

@implementation LoginViewController


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Facebook Profile";
    LoginView *view = [[LoginView alloc] initWithFrame: [UIScreen mainScreen].bounds];
    [self setView: view];
    [view.loginButton addTarget:self action:@selector(loginButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];

    // Check if user is cached and linked to Facebook, if so, bypass login
//    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
//        [self.navigationController pushViewController:[[RecentViewController alloc] init] animated:YES];
//    }
}


#pragma mark - Login mehtods

/* Login to facebook method */
- (void)loginButtonTouchHandler:(id)sender  {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
    
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        [_activityIndicator stopAnimating]; // Hide loading indicator
        
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"Uh oh. The user cancelled the Facebook login." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
        } else if (user.isNew) {
            NSLog(@"User with facebook signed up and logged in!");
            self.navigationController.navigationBarHidden = NO;
            
            [self.navigationController pushViewController:[[RecentViewController alloc] init] animated:YES];
            
        } else {
            NSLog(@"User with facebook logged in!");
           //[self.navigationController pushViewController:[[RecentViewController alloc] init] animated:YES];
//            AppDelegate *ad = [[AppDelegate alloc] init];
//            [ad.window setRootViewController:ad.tabBarController];
//            [ad.window makeKeyAndVisible];
            [self dismissViewControllerAnimated:YES completion:nil];
            self.tabBarController.selectedIndex = 0;

        }
    }];
    RecentViewController *recent = [[RecentViewController alloc] init];
    [recent startStandardUpdates];
    
    [_activityIndicator startAnimating]; // Show loading indicator until login is finished
}

@end
