//
//  GestureAppDelegate.h
//  Gesture
//
//  Created by Alan Pearson on 6/9/09.
//  Copyright Peekeez, Inc. 2009. All rights reserved.
//

#import "Gesture.h"

@class GestureViewController;

@interface GestureAppDelegate : NSObject <UIApplicationDelegate,UIAccelerometerDelegate> {
    UIWindow *window;
    GestureViewController *viewController;

	UIAccelerationValue	myAccelerometer[3];
	CFTimeInterval		lastTime;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet GestureViewController *viewController;

@end

