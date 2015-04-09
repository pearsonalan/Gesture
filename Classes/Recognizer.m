//
//  Recognizer.m
//  Gesture
//
//  Created by Alan Pearson on 6/17/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#import "Recognizer.h"
#import "Vector.h"
#import "Geometry.h"
#import "ConvexHull.h"
#import "stdarg.h"

int segment_y_comparison_function( const void* a, const void * b) {
	return (*(Segment **)a).start.y - (*(Segment **)b).start.y ;
}

@interface Recognizer (PrivateMethods)
- (void)findCenterPoint ;
@end

@implementation PlayDescription

- (id)init {
	self = [super init];
	if (self != nil) {
		positions = [[NSMutableArray alloc] init];
		bases = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)addPosition:(NSString*)s {
	[positions addObject:s];
}

- (void)addBase:(NSString*)s {
	[bases addObject:s];
}

- (NSString *)annotation {
    return [[annotation retain] autorelease];
}

- (void)setAnnotation:(NSString *)value {
    if (annotation != value) {
        [annotation release];
        annotation = [value copy];
    }
}

- (NSString*)description {
	NSMutableString * s = [[[NSMutableString alloc] init] autorelease];
	
	[s appendString:[positions componentsJoinedByString:@"-"]];
	if ([bases count] > 0) {
		[s appendString:@" "];
		[s appendString:[bases componentsJoinedByString:@" "]];
	}
	if (annotation) {
		[s appendString:@" "];
		[s appendString:annotation];
	}
	
	return [[s copy] autorelease];
}

- (void) dealloc {
	[positions release];
	[bases release];
	[super dealloc];
}


@end


@implementation PlayRecognizer

- (id)initWithStrokes:(NSArray*)strokesIn {
	self = [super init];
	if (self != nil) {
		strokes = [strokesIn mutableCopy];
	}
	return self;
}

- (PlayDescription*)matchPlay {
	PlayDescription * pdesc = [[PlayDescription alloc] init];
	float bestScore = 0.0;
	Recognizer * rBest = nil;
		
	// look for position touches
	Recognizer * positionRecognizer = [[RecognizerPosition alloc] initWithStrokes:strokes playDescription:pdesc];
	[positionRecognizer match];
	[strokes removeObjectsInArray:[positionRecognizer matchedStrokes]];
	[positionRecognizer release];
	
	Recognizer * basePathRecognizer = [[RecognizerBasePath alloc] initWithStrokes:strokes playDescription:pdesc];
	float basePathScore = [basePathRecognizer match];
	dprintf("recognizer score for %s is %0.3f\n", [[basePathRecognizer description] UTF8String], basePathScore);
	[strokes removeObjectsInArray:[basePathRecognizer matchedStrokes]];
	[basePathRecognizer release];
	
	int i;
	for (i = 0; i < 6; i++) {
		Recognizer * r = nil;
		switch (i) {
			case 0:
				r = [RecognizerK alloc];
				break;
			case 1:
				r = [RecognizerE alloc];
				break;
			case 2:
				r = [RecognizerF alloc];
				break;
			case 3:
				r = [RecognizerC alloc];
				break;
			case 4:
				r = [RecognizerL alloc];
				break;
			case 5:
				r = [RecognizerFC alloc];
				break;
		}
		
		[r initWithStrokes:strokes playDescription:pdesc];
		[r match];
		float score = [r score];
		dprintf("recognizer score for %s is %0.3f\n", [[r description] UTF8String], score);
		if (score > bestScore) {
			if (rBest) {
				[rBest release];
				rBest = nil;
			}
			rBest = [r retain];
			bestScore = score;
		}
		
		[r release];
	}
		
	if (rBest) {
		// [self setRecognizer:rBest];
		// [gestureView setNeedsDisplay];
		[pdesc setAnnotation:[rBest annotation]];
		[rBest release];
	}
	
	printf("Play: %s\n", [[pdesc description] UTF8String]);
	return [pdesc autorelease];
}

- (void)dealloc {
	[strokes release];
	[super dealloc];
}

@end

@implementation Recognizer

- (id)initWithStrokes:(NSArray*)strokesIn playDescription:(PlayDescription*)pdescIn {
	self = [super init];
	if (self != nil) {
		strokes = [strokesIn copy];
		pdesc = [pdescIn retain];

		matchedStrokes = [[NSMutableArray alloc] init];
		
		// gather all segments into an array
		segments = [[NSMutableArray alloc] init];
		for (Stroke * stroke in strokes) {
			[segments addObjectsFromArray:[stroke segments]];
		}

		// compute the convex hull of all strokes
		convexHull = [[ConvexHull alloc] initWithStrokes:strokes];
		[convexHull compute];

		// compute the center point of the convex hull
		[self findCenterPoint];
	}
	return self;
}

@synthesize score;

- (float)match {
	return score;
}

- (NSString *)annotation {
	return @"";
}

- (void)findCenterPoint {
	centerPoint = [convexHull centerPoint];
}

- (NSArray*)matchedStrokes {
	return [[matchedStrokes copy] autorelease];
}

- (void)drawRect:(CGRect)rect context:(CGContextRef)context {
	int i;
	
	int hullSize = convexHull.size;
	CGPoint * hull = convexHull.hull;
	
	CGContextSetLineWidth(context,2.0);
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextBeginPath(context);
	CGContextMoveToPoint(context,hull->x,hull->y);
	for (i = 1; i < hullSize; i++) {
		CGContextAddLineToPoint(context,hull[i].x,hull[i].y);
	}
	CGContextAddLineToPoint(context,hull->x,hull->y);
	CGContextDrawPath(context, kCGPathStroke);
	
	// draw center point
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextFillEllipseInRect(context, CGRectMake(centerPoint.x-2, centerPoint.y-2, 4, 4));
}


- (void)dealloc {
	[pdesc release];
	[strokes release];
	[matchedStrokes release];
	[segments release];
	[convexHull release];
	[super dealloc];
}

- (float)matchSegment:(Segment*)segment withVectorTo:(CGPoint)end {
	Vector * vec = [[Vector alloc] initWithStart:segment.start end:segment.end];
	Vector * referenceVector = [[Vector alloc] initWithStart:CGPointZero end:end];
	float cos_angle = (referenceVector.x * vec.x + referenceVector.y * vec.y) / (sqrt(referenceVector.x * referenceVector.x + referenceVector.y * referenceVector.y) * sqrt(vec.x * vec.x + vec.y * vec.y));
	[vec release];
	[referenceVector release];
	cos_angle = MAX(cos_angle,0.0);
	//dprintf("Direction match = %.3f\n",cos_angle);
	return cos_angle;
}

- (float)matchPointLeftOfCenter:(CGPoint)pt named:(char *)name  {
	//dprintf("%s left of center = %s\n", name, pt.x < centerPoint.x ? "TRUE" : "FALSE");
	return pt.x < centerPoint.x ? 1.0 : 0.0;
}

- (float)matchPointRightOfCenter:(CGPoint)pt named:(char *)name  {
	//dprintf("%s right of center = %s\n", name, pt.x > centerPoint.x ? "TRUE" : "FALSE");
	return pt.x > centerPoint.x ? 1.0 : 0.0;
}

- (float)matchPointAboveCenter:(CGPoint)pt named:(char *)name  {
	//dprintf("%s above center = %s\n", name, pt.y < centerPoint.y ? "TRUE" : "FALSE");
	return pt.y < centerPoint.y ? 1.0 : 0.0;
}

- (float)matchPointBelowCenter:(CGPoint)pt named:(char *)name  {
	//dprintf("%s below center = %s\n", name, pt.y > centerPoint.y ? "TRUE" : "FALSE");
	return pt.y > centerPoint.y ? 1.0 : 0.0;
}

- (float)matchPointOnHull:(CGPoint)pt named:(char *)name  {
	BOOL onHull = [convexHull isPointInHull:pt];
	//dprintf("%s on hull %s\n", name, onHull ? "TRUE" : "FALSE");
	return onHull ? 1.0 : 0.0;
}

- (float)matchPoint:(CGPoint)pt leftOfCenter:(CGPoint)cpt  named:(char *)name  {
	//dprintf("%s left of center = %s\n", name, pt.x < cpt.x ? "TRUE" : "FALSE");
	return pt.x < cpt.x ? 1.0 : 0.0;
}

- (float)matchPoint:(CGPoint)pt rightOfCenter:(CGPoint)cpt named:(char *)name  {
	//dprintf("%s right of center = %s\n", name, pt.x > cpt.x ? "TRUE" : "FALSE");
	return pt.x > cpt.x ? 1.0 : 0.0;
}

- (float)matchPoint:(CGPoint)pt aboveCenter:(CGPoint)cpt named:(char *)name  {
	//dprintf("%s above center = %s\n", name, pt.y < cpt.y ? "TRUE" : "FALSE");
	return pt.y < cpt.y ? 1.0 : 0.0;
}

- (float)matchPoint:(CGPoint)pt belowCenter:(CGPoint)cpt named:(char *)name  {
	//dprintf("%s below center = %s\n", name, pt.y > cpt.y ? "TRUE" : "FALSE");
	return pt.y > cpt.y ? 1.0 : 0.0;
}


- (float)product:(float*)array count:(int)count {
	int i; 
	float p = array[0];
	for (i = 1; i < count; i++) {
		p = p * array[i];
	}
	return p;
}
	
@end


@interface RecognizerK1 : Recognizer {
}
- (float)match;
@end

@implementation RecognizerK1

- (float)matchSegment0:(Segment*)segment {
	// look for SEG 0 down
	float scores[7];
	//dprintf("Segment 0 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(0.0f,1.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointAboveCenter:segment.start named:"Start"];
	scores[3] = [self matchPointLeftOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointBelowCenter:segment.end named:"End"];
	scores[5] = [self matchPointOnHull:segment.start named:"Start"];
	scores[6] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:7];
}

- (float)matchSegment1:(Segment*)segment {
	// look for segment 1 characteristics
	//dprintf("Segment 1 match:\n");
	float scores[5];
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(-1.0f,1.0f)];
	scores[1] = [self matchPointRightOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointAboveCenter:segment.start named:"Start"];
	scores[3] = [self matchPointLeftOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointOnHull:segment.start named:"Start"];
	return [self product:scores count:5];
}

- (float)matchSegment2:(Segment*)segment {
	// look for segment 2 characteristics
	//dprintf("Segment 2 match:\n");
	float scores[5];
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,1.0f)];
	scores[1] = [self matchPointRightOfCenter:segment.end named:"End"];
	scores[2] = [self matchPointBelowCenter:segment.end named:"End"];
	scores[3] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[4] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:5];
}

- (float)match {
	//dprintf("RecognizerK1: Looking for K1\n");
	
	if ([segments count] != 3)
		return score = 0.0;
	
	// look for SEG 1 down, SEG 2 top leg, SEG 3 bottom leg
	float scores[3];
	scores[0] = [self matchSegment0:[segments objectAtIndex:0]];
	//dprintf("Segment 0 score = %0.3f\n",scores[0]);
	scores[1] = [self matchSegment1:[segments objectAtIndex:1]];
	//dprintf("Segment 1 score = %0.3f\n",scores[1]);
	scores[2] = [self matchSegment2:[segments objectAtIndex:2]];
	//dprintf("Segment 2 score = %0.3f\n",scores[2]);
	score = [self product:scores count:3];
	//dprintf("Recognizer K1 score = %0.3f\n",score);
	return score;
}

@end


@interface RecognizerK2 : Recognizer {
}
- (float)match;
@end

@implementation RecognizerK2

- (float)matchSegment0:(Segment*)segment {
	// look for SEG 0 down
	float scores[7];
	//dprintf("Segment 0 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(0.0f,1.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointAboveCenter:segment.start named:"Start"];
	scores[3] = [self matchPointLeftOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointBelowCenter:segment.end named:"End"];
	scores[5] = [self matchPointOnHull:segment.start named:"Start"];
	scores[6] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:7];
}

- (float)matchSegment1:(Segment*)segment {
	// look for segment 1 characteristics
	//dprintf("Segment 1 match:\n");
	float scores[5];
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,-1.0f)];
	scores[1] = [self matchPointRightOfCenter:segment.end named:"End"];
	scores[2] = [self matchPointAboveCenter:segment.end named:"End"];
	scores[3] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[4] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:5];
}

- (float)matchSegment2:(Segment*)segment {
	// look for segment 2 characteristics
	//dprintf("Segment 2 match:\n");
	float scores[5];
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,1.0f)];
	scores[1] = [self matchPointRightOfCenter:segment.end named:"End"];
	scores[2] = [self matchPointBelowCenter:segment.end named:"End"];
	scores[3] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[4] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:5];
}

- (float)match {
	//dprintf("RecognizerK2: Looking for K2\n");
	
	if ([segments count] != 3)
		return score = 0.0;
	
	// look for SEG 1 down, SEG 2 top leg, SEG 3 bottom leg
	float scores[3];
	scores[0] = [self matchSegment0:[segments objectAtIndex:0]];
	//dprintf("Segment 0 score = %0.3f\n",scores[0]);
	scores[1] = [self matchSegment1:[segments objectAtIndex:1]];
	//dprintf("Segment 1 score = %0.3f\n",scores[1]);
	scores[2] = [self matchSegment2:[segments objectAtIndex:2]];
	//dprintf("Segment 2 score = %0.3f\n",scores[2]);
	score = [self product:scores count:3];
	//dprintf("Recognizer K2 score = %0.3f\n",score);
	return score;
}

@end


@implementation RecognizerK

- (NSString *)description {
	return @"K Recognizer";
}

- (NSString *)annotation {
	return @"K";
}

- (float)match {
	//dprintf("RecognizerK: Looking for K\n");
	
	Recognizer * k1 = [[RecognizerK1 alloc] initWithStrokes:strokes playDescription:pdesc];
	Recognizer * k2 = [[RecognizerK2 alloc] initWithStrokes:strokes playDescription:pdesc];

	float scores[2];
	scores[0] = [k1 match];
	scores[1] = [k2 match];
	score = MAX(scores[0],scores[1]);
	//dprintf("Recognizer K score = %0.3f\n",score);
	return score;
}

@end


// 4-stroke E recognizer
@implementation RecognizerE

- (NSString *)description {
	return @"E Recognizer";
}

- (NSString *)annotation {
	return @"E";
}


- (float)matchSegment0:(Segment*)segment {
	// look for SEG 0 as down line
	float scores[5];
	//dprintf("Segment 0 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(0.0f,1.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointAboveCenter:segment.start named:"Start"];
	scores[3] = [self matchPointLeftOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointBelowCenter:segment.end named:"End"];
	return [self product:scores count:5];
}

- (float)matchSegment1:(Segment*)segment {
	// look for SEG 1 as top hotizontal line
	float scores[6];
	//dprintf("Segment 1 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,0.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointAboveCenter:segment.start named:"Start"];
	scores[3] = [self matchPointRightOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointAboveCenter:segment.end named:"End"];
	scores[5] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:6];
}

- (float)matchSegment2:(Segment*)segment {
	// look for SEG 2 as center hotizontal line
	float scores[3];
	//dprintf("Segment 2 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,0.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointRightOfCenter:segment.end named:"End"];
	return [self product:scores count:3];
}

- (float)matchSegment3:(Segment*)segment {
	// look for SEG 3 as bottom hotizontal line
	float scores[6];
	//dprintf("Segment 3 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,0.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointBelowCenter:segment.start named:"Start"];
	scores[3] = [self matchPointRightOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointBelowCenter:segment.end named:"End"];
	scores[5] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:6];
}


- (float)match {
	//dprintf("RecognizerE: Looking for E\n");
	
	//if ([strokes count] != 4)
	//	return score = 0.0;
	
	if ([segments count] != 4)
		return score = 0.0;
	
	Segment * horizontalSegments[3];
	horizontalSegments[0] = [segments objectAtIndex:1];
	horizontalSegments[1] = [segments objectAtIndex:2];
	horizontalSegments[2] = [segments objectAtIndex:3];
	qsort(horizontalSegments,3,sizeof(Segment*),segment_y_comparison_function);
	
	// look for SEG 1 down, SEG 2 top, SEG 3 middle, SEG 4 bottom
	float scores[4];
	scores[0] = [self matchSegment0:[segments objectAtIndex:0]];
	//dprintf("Segment 0 score = %0.3f\n",scores[0]);
	scores[1] = [self matchSegment1:horizontalSegments[0]];
	//dprintf("Segment 1 score = %0.3f\n",scores[1]);
	scores[2] = [self matchSegment2:horizontalSegments[1]];
	//dprintf("Segment 2 score = %0.3f\n",scores[2]);
	scores[3] = [self matchSegment3:horizontalSegments[2]];
	//dprintf("Segment 3 score = %0.3f\n",scores[3]);
	score = [self product:scores count:4];
	//dprintf("Recognizer E score = %0.3f\n",score);
	return score;
}

@end


// L recognizer
@implementation RecognizerL

- (NSString *)description {
	return @"L Recognizer";
}

- (NSString *)annotation {
	return @"L";
}

- (float)matchSegment0:(Segment*)segment {
	// look for SEG 0 as down line
	float scores[6];
	//dprintf("Segment 0 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(0.0f,1.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointAboveCenter:segment.start named:"Start"];
	scores[3] = [self matchPointLeftOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointBelowCenter:segment.end named:"End"];
	scores[5] = [self matchPointOnHull:segment.start named:"Start"];
	return [self product:scores count:6];
}

- (float)matchSegment1:(Segment*)segment {
	// look for SEG 1 as bottom hotizontal line
	float scores[6];
	//dprintf("Segment 1 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,0.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointBelowCenter:segment.start named:"Start"];
	scores[3] = [self matchPointRightOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointBelowCenter:segment.end named:"End"];
	scores[5] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:6];
}


- (float)match {
	//dprintf("RecognizerL: Looking for L\n");
	
	//if ([strokes count] != 4)
	//	return score = 0.0;
	
	if ([segments count] != 2)
		return score = 0.0;
	
	
	// look for SEG 1 down, SEG 2 top, SEG 3 middle, SEG 4 bottom
	float scores[2];
	scores[0] = [self matchSegment0:[segments objectAtIndex:0]];
	//dprintf("Segment 0 score = %0.3f\n",scores[0]);
	scores[1] = [self matchSegment1:[segments objectAtIndex:1]];
	//dprintf("Segment 1 score = %0.3f\n",scores[1]);
	score = [self product:scores count:2];
	//dprintf("Recognizer L score = %0.3f\n",score);
	return score;
}

@end


// F recognizer
@implementation RecognizerF

- (NSString *)description {
	return @"F Recognizer";
}

- (NSString *)annotation {
	return @"F";
}

- (float)matchSegment0:(Segment*)segment {
	// look for SEG 0 as down line
	float scores[5];
	//dprintf("Segment 0 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(0.0f,1.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointAboveCenter:segment.start named:"Start"];
	scores[3] = [self matchPointLeftOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointBelowCenter:segment.end named:"End"];
	return [self product:scores count:5];
}

- (float)matchSegment1:(Segment*)segment {
	// look for SEG 1 as top hotizontal line
	float scores[6];
	//dprintf("Segment 1 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,0.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointAboveCenter:segment.start named:"Start"];
	scores[3] = [self matchPointRightOfCenter:segment.end named:"End"];
	scores[4] = [self matchPointAboveCenter:segment.end named:"End"];
	scores[5] = [self matchPointOnHull:segment.end named:"End"];
	return [self product:scores count:6];
}

- (float)matchSegment2:(Segment*)segment {
	// look for SEG 2 as center hotizontal line
	float scores[3];
	//dprintf("Segment 2 match:\n");
	scores[0] = [self matchSegment:segment withVectorTo:CGPointMake(1.0f,0.0f)];
	scores[1] = [self matchPointLeftOfCenter:segment.start named:"Start"];
	scores[2] = [self matchPointRightOfCenter:segment.end named:"End"];
	return [self product:scores count:3];
}

- (float)match {
	//dprintf("RecognizerF: Looking for F\n");
	
	//if ([strokes count] != 4)
	//	return score = 0.0;
	
	if ([segments count] != 3)
		return score = 0.0;
	
	Segment * horizontalSegments[3];
	horizontalSegments[0] = [segments objectAtIndex:1];
	horizontalSegments[1] = [segments objectAtIndex:2];
	qsort(horizontalSegments,2,sizeof(Segment*),segment_y_comparison_function);
	
	// look for SEG 1 down, SEG 2 top, SEG 3 middle
	float scores[3];
	scores[0] = [self matchSegment0:[segments objectAtIndex:0]];
	//dprintf("Segment 0 score = %0.3f\n",scores[0]);
	scores[1] = [self matchSegment1:horizontalSegments[0]];
	//dprintf("Segment 1 score = %0.3f\n",scores[1]);
	scores[2] = [self matchSegment2:horizontalSegments[1]];
	//dprintf("Segment 2 score = %0.3f\n",scores[2]);
	score = [self product:scores count:3];
	//dprintf("Recognizer F score = %0.3f\n",score);
	return score;
}

@end

@implementation RecognizerC

- (NSString *)description {
	return @"C Recognizer";
}

- (NSString *)annotation {
	return @"C";
}

- (float)match {
	if ([strokes count] != 1)
		return 0.0;
	
	Stroke * stroke = [strokes objectAtIndex:0];
	
	// all vector end points should be on the hull
	for (Vector * vec in [stroke vectors]) {
		if (![convexHull isPointInHull:vec.start]) 
			return 0.0;
		if (![convexHull isPointInHull:vec.end]) 
			return 0.0;
	}
	
	float scores[4];
	
	// the stroke start should be in the upper right quadrant of the hull
	scores[0] = [self matchPointRightOfCenter:stroke.start named:"Start"];
	scores[1] = [self matchPointAboveCenter:stroke.start named:"Start"];
	
	// the stroke end should be in the lower right quadrant of the hull
	scores[2] = [self matchPointRightOfCenter:stroke.end named:"End"];
	scores[3] = [self matchPointBelowCenter:stroke.end named:"End"];
	
	score = [self product:scores count:4];
	//dprintf("Recognizer C score = %0.3f\n",score);
	return score;
}

@end

// 4-stroke FC recognizer
@implementation RecognizerFC

- (NSString *)description {
	return @"FC Recognizer";
}

- (NSString *)annotation {
	return @"FC";
}

- (float)match {
	//dprintf("RecognizerFC: Looking for FC\n");
	
	if ([strokes count] != 4)
		return score = 0.0;

	NSArray * fStrokes = [strokes subarrayWithRange:NSMakeRange(0, 3)];
	NSArray * cStrokes = [strokes subarrayWithRange:NSMakeRange(3, 1)];

	frec = [[RecognizerF alloc] initWithStrokes:fStrokes playDescription:pdesc];
	crec = [[RecognizerC alloc] initWithStrokes:cStrokes playDescription:pdesc];
	
	float scores[2];
	scores[0] = [frec match];
	scores[1] = [crec match];
	score = [self product:scores count:2];
	//dprintf("Recognizer FC score = %0.3f\n",score);
	return score;
}

- (void)drawRect:(CGRect)rect context:(CGContextRef)context {
	[frec drawRect:rect context:context];
	[crec drawRect:rect context:context];
}

- (void) dealloc {
	[frec release];
	[crec release];
	[super dealloc];
}

@end


#define BASES 5
static CGPoint bases[BASES] = { 
	{ 160.0f, 354.0f },			// home plate
	{ 255.0f, 252.0f },			// 1b
	{ 160.0f, 152.0f },			// 2b
	{  65.0f, 252.0f },			// 3b
	{ 160.0f, 354.0f }			// home plate
};

@implementation RecognizerBasePath

- (NSString *)description {
	return @"BasePath Recognizer";
}

- (float)matchPoint:(CGPoint)point toBase:(CGPoint)base {	
	float distance = Magnitude(&point,&base);
	dprintf("point to base distance is %.3f\n", distance);
	float f = 1.5f - distance / 30.0f;
	return MIN(MAX(f,0.0f),1.0f);
}

- (float)match {
	int i, j;
	float scores[5];
	
	dprintf("RecognizerBasePath: analyzing segments\n");
	
	if ([segments count] > 4) {
		dprintf("RecognizerBasePath: too many segments\n");
		return score = 0.0;
	}
	
	if ([segments count] == 0) {
		dprintf("RecognizerBasePath: not enough segments\n");
		return score = 0.0;
	}
	
	// find the base that starts the first segment
	Segment * firstSegment = [segments objectAtIndex:0];
	CGPoint pathStart = [firstSegment start];
	dprintf("Looking for base at %.3f,%.3f\n", pathStart.x, pathStart.y);
	for (i = 0; i < BASES-1; i++) {
		float s = [self matchPoint:pathStart toBase:bases[i]];
		if (s > 0.0) {
			dprintf("Matched point at %.3f,%.3f to base %d\n", pathStart.x, pathStart.y, i);
			
			if ([segments count] > 4 - i) {
				dprintf("too many segments for start at base %d.\n", i);
				return score = 0;
			}
			
			scores[0] = s;
			int startBase = i;
			dprintf("RecognizerBasePath: start score (base %d) = %0.3f\n",i,scores[0]);
			for (j = 0, i = i+1; j < [segments count]; j++, i++) {
				assert( i < BASES );
				Segment * seg = [segments objectAtIndex:j];
				CGPoint endPoint = [seg end];
				scores[j+1] = [self matchPoint:endPoint toBase:bases[i]];
				dprintf("RecognizerBasePath: segment end score (base %d) = %0.3f\n",i,scores[j+1]);
			}
			
			score = [self product:scores count:[segments count]+1];
			dprintf("RecognizerBasePath: match score = %0.3f\n",score);
			
			if (score > 0.0) {
				for (j = 0, i = startBase+1; j < [segments count]; j++, i++) {
					[pdesc addBase:[NSString stringWithFormat:@"%dB", i]];
				}
			}
			
			return score;
		}
	}
	
	dprintf("RecognizerBasePath: count not match first segment\n");
	
	return score = 0.0;
}

@end

#define POSITIONS 9

static CGPoint positions[POSITIONS] = { 
{ 160.0f, 252.0f },			// pitcher
{ 160.0f, 380.0f },			// catcher
{ 260.0f, 218.0f },			// first
{ 198.0f, 156.0f },			// second
{  55.0f, 218.0f },			// third
{ 124.0f, 156.0f },			// shortstop
{  39.0f, 122.0f },			// left field
{ 160.0f,  70.0f },			// center field
{ 295.0f, 122.0f }			// right field
};

@implementation RecognizerPosition

- (float)matchPoint:(CGPoint)point toPosition:(CGPoint)position {	
	if (position.x - 30.0f < point.x && point.x < position.x + 30.0f &&
		position.y - 30.0f < point.y && point.y < position.y + 30.0f ) {
		float distance = Magnitude(&point,&position);
		float f = 1.5f - distance / 20.0f;
		return MIN(MAX(f,0.0f),1.0f);
	} else {
		return 0.0f;
	}
}

- (float)match {
	score = 0.0f;
	for (Stroke * stroke in strokes) {
		if ([[stroke vectors] count] == 1) {
			Vector * vec = [[stroke vectors] objectAtIndex:0] ;
			if ([vec length] < 20.0f) {
				dprintf("Stroke is a single point.\n");
				for (int i = 0; i < POSITIONS; i++) {
					if (score = [self matchPoint:[vec end] toPosition:positions[i]]) {
						dprintf("Stroke matches position %d. score = %.3f\n", i+1, score);
						[matchedStrokes addObject:stroke];
						[pdesc addPosition:[NSString stringWithFormat:@"%d", i+1]];
						break;
					}
				}
			}
		}
	}
	return score;
}

@end
