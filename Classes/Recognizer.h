//
//  Recognizer.h
//  Gesture
//
//  Created by Alan Pearson on 6/17/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#import "Gesture.h"
#import "ConvexHull.h"

@interface PlayDescription : NSObject {
	NSMutableArray * positions;
	NSMutableArray * bases;
	NSString * annotation;
}
- (void)addPosition:(NSString*)s;
- (void)addBase:(NSString*)s;
- (NSString *)annotation;
- (void)setAnnotation:(NSString*)s;
- (NSString*)description;
@end

@interface PlayRecognizer : NSObject {
	NSMutableArray * strokes;
}
- (id)initWithStrokes:(NSArray*)strokesIn;
- (PlayDescription*)matchPlay;
@end

@interface Recognizer : NSObject {
	PlayDescription * pdesc;
	NSArray * strokes;
	NSMutableArray * matchedStrokes;
	NSMutableArray * segments;
	ConvexHull * convexHull;
	float score;
	CGPoint centerPoint;
}
- (id)initWithStrokes:(NSArray*)strokesIn playDescription:(PlayDescription*)pdescIn;
- (float)match;
- (void)drawRect:(CGRect)rect context:(CGContextRef)context ;
- (NSArray*)matchedStrokes;
- (NSString *)annotation;
@property (assign,readonly) float score;
@property (readonly) NSArray * matchedStrokes;
@end

@interface RecognizerK : Recognizer {
}
- (float)match;
- (NSString *)annotation;
@end

@interface RecognizerE : Recognizer {
}
- (float)match;
- (NSString *)annotation;
@end

@interface RecognizerL : Recognizer {
}
- (float)match;
- (NSString *)annotation;
@end

@interface RecognizerF : Recognizer {
}
- (float)match;
- (NSString *)annotation;
@end

@interface RecognizerC : Recognizer {
}
- (float)match;
- (NSString *)annotation;
@end

@interface RecognizerFC : Recognizer {
	RecognizerF * frec;
	RecognizerC * crec;
}
- (float)match;
- (NSString *)annotation;
@end

@interface RecognizerBasePath : Recognizer {
}
- (float)match;
@end

@interface RecognizerPosition : Recognizer {
}
- (float)match;
@end
