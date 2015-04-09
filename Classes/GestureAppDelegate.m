//
//  GestureAppDelegate.m
//  Gesture
//
//  Created by Alan Pearson on 6/9/09.
//  Copyright Peekeez, Inc. 2009. All rights reserved.
//

#import "GestureAppDelegate.h"
#import "GestureViewController.h"
#import "GestureView.h"

#define kAccelerometerFrequency			25 //Hz
#define kFilteringFactor				0.1
#define kMinEraseInterval				0.5
#define kEraseAccelerationThreshold		2.0

@implementation GestureAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    [application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];

	//Configure and enable the accelerometer
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}

// Called when the accelerometer detects motion; plays the erase sound and redraws the view if the motion is over a threshold.
- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
	UIAccelerationValue				length,
	x,
	y,
	z;
	
	//Use a basic high-pass filter to remove the influence of the gravity
	myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
	myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
	myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
	// Compute values for the three axes of the acceleromater
	x = acceleration.x - myAccelerometer[0];
	y = acceleration.y - myAccelerometer[0];
	z = acceleration.z - myAccelerometer[0];
	
	//Compute the intensity of the current acceleration 
	length = sqrt(x * x + y * y + z * z);
	// If above a given threshold, play the erase sounds and erase the drawing view
	if((length >= kEraseAccelerationThreshold) && (CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval)) {
		[viewController erase:self];
		lastTime = CFAbsoluteTimeGetCurrent();
	}
}

- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}

@end
