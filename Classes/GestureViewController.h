//
//  GestureViewController.h
//  Gesture
//
//  Created by Alan Pearson on 6/9/09.
//  Copyright Peekeez, Inc. 2009. All rights reserved.
//

#import "Gesture.h"
#import "Recognizer.h"
#import "Vector.h"

@class GestureView;

@interface GestureViewController : UIViewController {
	IBOutlet GestureView * gestureView;
	IBOutlet UILabel * playDescriptionLabel;
	NSMutableArray * strokes;
	NSMutableDictionary * activeStrokes;
	PlayDescription * playDescription;
	NSTimer * gesturesCompletedTimer;
}

- (IBAction)runRecognizer:(id)sender;
- (IBAction)erase:(id)sender;

@property (readonly) IBOutlet GestureView * gestureView;
@property (readonly,retain) NSArray * strokes;
@property (retain) PlayDescription * playDescription;


@end

