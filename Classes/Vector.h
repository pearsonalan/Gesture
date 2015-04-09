//
//  Vector.h
//  Gesture
//
//  Created by Alan Pearson on 6/9/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Vector : NSObject {
    CGPoint         start;
    CGPoint         end;
	float			angle;
}
- (id) initWithStart:(CGPoint)s end:(CGPoint)e;
- (float) length;
@property (assign,readonly) CGPoint start;
@property (assign,readonly) CGPoint end;
@property (assign,readonly) float angle;

@property (assign,readonly) float x;
@property (assign,readonly) float y;
@end


@interface TouchVector : Vector {
    UITouchPhase    phase;
}
- (id) initWithTouch:(UITouch*)touch inView:(UIView*)view;
@property (assign,readonly) UITouchPhase phase;
@property (assign,readonly) CGPoint locationInView;
@property (assign,readonly) CGPoint previousLocationInView;
@end


@interface Stroke : NSObject {
	NSMutableArray *touchVectors;
	CGFloat		   *color;
	BOOL			coalesced;
	CGPoint			startPoint, endPoint;
	NSMutableArray *coalescedVectors;
	NSMutableArray *segments;
}
- (id)initWithColor:(CGFloat*)colorVec;
- (void)addTouchVector:(TouchVector*)vec;
- (void)drawRect:(CGRect)rect context:(CGContextRef)context ;
- (TouchVector*)lastVector;
- (void)coalesceVectors ;

- (NSArray*)segments;
- (NSArray*)vectors;

@property (assign,readonly) CGPoint start;
@property (assign,readonly) CGPoint end;
@property (assign,readonly) NSUInteger vectorCount;

@end


@interface Segment : NSObject {
	CGPoint			start, end;
	CGFloat		   *color;
	NSMutableArray *vectors;
}
- (void)addVector:(Vector*)vec;
- (void)drawRect:(CGRect)rect context:(CGContextRef)context ;
@property (assign,readonly) CGPoint start;
@property (assign,readonly) CGPoint end;
@property (retain,readonly) NSArray * vectors;
@end