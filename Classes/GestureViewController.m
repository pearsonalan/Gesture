//
//  GestureViewController.m
//  Gesture
//
//  Created by Alan Pearson on 6/9/09.
//  Copyright Peekeez, Inc. 2009. All rights reserved.
//

#import "GestureViewController.h"
#import "GestureView.h"
#import "Recognizer.h"
#import "ColorAllocator.h"

@interface GestureViewController (PrivateMethods)
- (void) startGestureCompletedTimer;
- (void) resetGestureCompletedTimer;
@end

@implementation GestureViewController

@synthesize gestureView;
@synthesize playDescription;

- (void)awakeFromNib {    
	strokes = [[NSMutableArray alloc] init];
	activeStrokes = [[NSMutableDictionary alloc] init];
}

- (NSArray *)strokes {
	return [[strokes copy] autorelease];
}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
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

- (IBAction)runRecognizer:(id)sender {
	//dprintf("Run recognizer: %d\n", [sender tag]);
}

- (IBAction)erase:(id)sender {
	[self resetGestureCompletedTimer];
	[strokes removeAllObjects];
	[activeStrokes removeAllObjects];
	self.playDescription = nil;
	[playDescriptionLabel setText:@""];
	[gestureView setNeedsDisplay];
}

- (Stroke*)makeNewStrokeForTouch:(UITouch*)touch {
	CGFloat * colorVec = [[ColorAllocator sharedInstance] nextColor];
	Stroke * stroke = [[[Stroke alloc] initWithColor:colorVec] autorelease];
	[strokes addObject:stroke];
	[activeStrokes setObject:stroke forKey:[NSNumber numberWithInt:(int)touch]];
	return stroke;
}

- (Stroke*)findStrokeForTouch:(UITouch*)touch {
	return [activeStrokes objectForKey:[NSNumber numberWithInt:(int)touch]];
}

- (void)gestureCompleted:(NSTimer*)timer {
	dprintf("Gesture completed\n");
	if (playDescription) {
		[playDescription release];
		playDescription = nil;
	}
	
	PlayRecognizer * playRecognizer = [[PlayRecognizer alloc] initWithStrokes:strokes];
	playDescription = [[playRecognizer matchPlay] retain];
	[playRecognizer release];
	[playDescriptionLabel setText:[playDescription description]];
	[gestureView setNeedsDisplay];
}

- (void) startGestureCompletedTimer {
	// stop any existing timer 
	[self resetGestureCompletedTimer];

	// start a timer
	gesturesCompletedTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(gestureCompleted:) userInfo:nil repeats:NO] retain];
}

- (void) resetGestureCompletedTimer {
	if (gesturesCompletedTimer) {
		// cancel the existing timer
		[gesturesCompletedTimer invalidate];
		[gesturesCompletedTimer release];
		gesturesCompletedTimer = nil;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//dprintf("touches began: %d touches\n", [touches count]);
	[self resetGestureCompletedTimer];
	
	CGRect rect = CGRectNull;
	for (UITouch * touch in touches) {
		Stroke * stroke = [self makeNewStrokeForTouch:touch];
		TouchVector * vec = [[TouchVector alloc] initWithTouch:touch inView:gestureView];
		[stroke addTouchVector:vec];
		CGRect r = CGRectMake(vec.locationInView.x-4, vec.locationInView.y-4, 8, 8);
		if (CGRectIsNull(rect)) {
			rect = r;
		} else {
			rect = CGRectUnion(rect, r);
		}
		[vec release];
	}
	
	[gestureView setNeedsDisplayInRect:rect];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	//dprintf("touches moved: %d touches\n", [touches count]);
	CGRect rect = CGRectNull;
	for (UITouch * touch in touches) {
		// if the touch has not moved, ignore it
		if ([touch locationInView:gestureView].x == [touch previousLocationInView:gestureView].x && [touch locationInView:gestureView].y == [touch previousLocationInView:gestureView].y) 
			continue;
		
		// if the touch is off the view, ignore it
		if ([touch locationInView:gestureView].x < 0.0 || [touch locationInView:gestureView].y < 0.0)
			continue;
		
		Stroke * stroke = [self findStrokeForTouch:touch];
		if (!stroke) 
			continue;
		
		TouchVector * vec = [[TouchVector alloc] initWithTouch:touch inView:gestureView];
		[stroke addTouchVector:vec];
		
		CGRect r = CGRectMake(MIN(vec.previousLocationInView.x, vec.locationInView.x) - 4 , 
							  MIN(vec.previousLocationInView.y, vec.locationInView.y) - 4, 
							  (vec.locationInView.x > vec.previousLocationInView.x ? vec.locationInView.x - vec.previousLocationInView.x : vec.previousLocationInView.x - vec.locationInView.x) + 8, 
  							  (vec.locationInView.y > vec.previousLocationInView.y ? vec.locationInView.y - vec.previousLocationInView.y : vec.previousLocationInView.y - vec.locationInView.y) + 8 );
		
		if (CGRectIsNull(rect)) {
			rect = r;
		} else {
			rect = CGRectUnion(rect, r);
		}
		
//		 dprintf("touch moved to %.0f,%.0f from %.0f,%.0f, angle = %.2f\n", 
//				 vec.locationInView.x, vec.locationInView.y, 
//				 vec.previousLocationInView.x, vec.previousLocationInView.y, 
//				 vec.angle);
		
		[vec release];
	}
	[gestureView setNeedsDisplayInRect:rect];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//dprintf("touches ended: %d touches\n", [touches count]);
	for (UITouch * touch in touches) {
		Stroke * stroke = [self findStrokeForTouch:touch];
		if (!stroke) 
			continue;
		
		//dprintf("  %.0f,%.0f\n", [touch locationInView:gestureView].x, [touch locationInView:gestureView].y);
		[stroke addTouchVector:[[[TouchVector alloc] initWithTouch:touch inView:gestureView] autorelease]];
		[activeStrokes removeObjectForKey:[NSNumber numberWithInt:(int)touch]];
		
		[stroke coalesceVectors];
	}
	[gestureView setNeedsDisplay];
	
	[self startGestureCompletedTimer];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch * touch in touches) {
		Stroke * stroke = [self findStrokeForTouch:touch];
		if (!stroke) 
			continue;
		[activeStrokes removeObjectForKey:[NSNumber numberWithInt:(int)touch]];
	}
}

- (void)dealloc {
	if (gesturesCompletedTimer) {
		// cancel the existing timer
		[gesturesCompletedTimer invalidate];
		[gesturesCompletedTimer release];
		gesturesCompletedTimer = nil;
	}

	[strokes release];
	[activeStrokes release];
	[playDescription release];
    [super dealloc];
}

@end
