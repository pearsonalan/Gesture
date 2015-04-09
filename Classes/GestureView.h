//
//  GestureView.h
//  Gesture
//
//  Created by Alan Pearson on 6/9/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#import "Gesture.h"

@class GestureViewController;

@interface GestureView : UIView {
	IBOutlet GestureViewController * viewController;
	UIImage * diamondImage;
	UIImage * positionButtonImage;
}

@end
