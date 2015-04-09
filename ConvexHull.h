//
//  ConvexHull.h
//  Gesture
//
//  Created by Alan Pearson on 6/14/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

void ComputeConvexHull( CGPoint * points_in, int n, CGPoint * hull, int * hull_size ) ;

@interface ConvexHull : NSObject {
	CGPoint * points;
	int pointCount;
	CGPoint * hull;
	int size;
}
- (id)initWithStrokes:(NSArray*)strokes;
- (id)initWithSegments:(NSArray*)segments;
- (void)addStrokes:(NSArray*)strokes;
- (void)addSegments:(NSArray*)segments;
- (void)compute;
- (BOOL)isPointInHull:(CGPoint)pt;
- (CGPoint)centerPoint;

@property (assign,readonly) int size;
@property (assign,readonly) CGPoint * hull;

@end

