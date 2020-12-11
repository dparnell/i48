//
//  RootViewController.m
//  i48
//
//  Created by Daniel Parnell on 14/04/09.
//  Copyright Automagic Software Pty Ltd 2009. All rights reserved.
//

#import "RootViewController.h"
#import "MainViewController.h"
#import "FlipsideViewController.h"
#import "UIDevice+Resolutions.h"

@implementation RootViewController

@synthesize infoButton;
@synthesize flipsideNavigationBar;
@synthesize mainViewController;
@synthesize flipsideViewController;


- (void)viewDidLoad {	
    [super viewDidLoad];

    UIDevice* device = [UIDevice currentDevice];
    UIDeviceResolution resolution = [device resolution];
	
	NSString* skin = [[NSUserDefaults standardUserDefaults] objectForKey: @"skin"];
	
    if(skin == nil) {
        skin = @"MainView";
    }
    
	if([device userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		skin = [skin stringByAppendingString: @"_iPad"];
	} else {
        if(resolution == UIDeviceResolution_iPhoneRetina5) {
            skin = [skin stringByAppendingString: @"_retina4"];
        } else {
            if(resolution == UIDeviceResolution_iPhoneRetina4) {
                skin = [skin stringByAppendingString: @"_retina35"];
            }
        }
    }
	
    MainViewController *viewController = [[MainViewController alloc] initWithNibName: skin bundle:nil];
	if (viewController && viewController.view) {
		self.mainViewController = viewController;
        self.view.backgroundColor = mainViewController.view.backgroundColor;
		[self.view insertSubview:mainViewController.view belowSubview:infoButton];
	}    
}


- (void)loadFlipsideViewController {    
    FlipsideViewController *viewController;
	
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		viewController = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView_iPad" bundle:nil];
	} else {
		viewController = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	}
	
	
    self.flipsideViewController = viewController;

	CGRect r = viewController.view.frame;
    // Set up the navigation bar
    UINavigationBar *aNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, r.size.width, 44.0)];
    aNavigationBar.barStyle = UIBarStyleBlack;
    self.flipsideNavigationBar = aNavigationBar;
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleView)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"i48", @"Application Title")];
    navigationItem.rightBarButtonItem = buttonItem;
    [flipsideNavigationBar pushNavigationItem:navigationItem animated:NO];
}


- (IBAction)toggleView {    
    /*
     This method is called when the info or Done button is pressed.
     It flips the displayed view from the main view to the flipside view and vice-versa.
     */
    if (flipsideViewController == nil) {
        [self loadFlipsideViewController];
    }
    
    UIView *mainView = mainViewController.view;
    UIView *flipsideView = flipsideViewController.view;

    [UIView transitionWithView:self.view
                      duration:1.0
                       options:([mainView superview] ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft)
                    animations:^{
        if ([mainView superview] != nil) {
            [self.flipsideViewController viewWillAppear:YES];
            [self.mainViewController viewWillDisappear:YES];
            [mainView removeFromSuperview];
            [self.infoButton removeFromSuperview];
            [self.view addSubview:flipsideView];
            [self.view insertSubview: self.flipsideNavigationBar aboveSubview:flipsideView];
            [self.mainViewController viewDidDisappear:YES];
            [self.flipsideViewController viewDidAppear:YES];
        } else {
            [self.mainViewController viewWillAppear:YES];
            [self.flipsideViewController viewWillDisappear:YES];
            [flipsideView removeFromSuperview];
            [self.flipsideNavigationBar removeFromSuperview];
            [self.view addSubview:mainView];
            [self.view insertSubview: self.infoButton aboveSubview: self.mainViewController.view];
            [self.flipsideViewController viewDidDisappear:YES];
            [self.mainViewController viewDidAppear:YES];
        }
    } completion: nil];
    
    [UIView animateWithDuration: 1.0 animations: ^{
        

    }];
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}




@end
