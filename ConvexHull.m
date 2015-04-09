//
//  ConvexHull.c
//  Gesture
//
//  Created by Alan Pearson on 6/14/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#if 1
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#else
#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#endif
#include <assert.h>
#include <alloca.h>
#include <stdio.h>
#include <stdlib.h>

#import "ConvexHull.h"
#import "Vector.h"

@implementation ConvexHull 

- (id) init {
	self = [super init];
	if (self != nil) {
		hull = 0;
		points = 0;
	}
	return self;
}

- (id)initWithStrokes:(NSArray*)strokes {
	if (![self init])
		return nil;
	[self addStrokes:strokes];
	return self;
}

- (id)initWithSegments:(NSArray*)segments {
	if (![self init])
		return nil;
	[self addSegments:segments];
	return self;
}

- (void)addStrokes:(NSArray*)strokes {
	int n = 0;
	for (Stroke * stroke in strokes) {
		n++;
		for (Vector * vec in [stroke vectors]) {
			n++;
		}
	}
	
	points = realloc(points,sizeof(CGPoint) * (pointCount+n));
	
	int i = pointCount;
	for (Stroke * stroke in strokes) {
		points[i] = [stroke start];
		i++;
		for (Vector * vec in [stroke vectors]) {
			points[i] = [vec end];
			i++;
		}
	}
	pointCount += n;
}

- (void)addSegments:(NSArray*)segments {
	int n = 0;
	for (Segment * segment in segments) {
		n++;
		for (Vector * vec in [segment vectors]) {
			n++;
		}
	}

	points = realloc(points,sizeof(CGPoint) * (pointCount+n));
	
	int i = pointCount;
	for (Segment * segment in segments) {
		points[i] = [segment start];
		i++;
		for (Vector * vec in [segment vectors]) {
			points[i] = [vec end];
			i++;
		}
	}
	pointCount += n;
}

- (void)compute {
	if (hull) {
		free(hull);
		hull = 0;
	}
	hull = malloc(sizeof(CGPoint) * pointCount);
	ComputeConvexHull(points,pointCount,hull,&size);
}

- (BOOL)isPointInHull:(CGPoint)pt {
	int i;
	for (i = 0; i < size; i++) {
		if (CGPointEqualToPoint(pt, hull[i])) 
			return YES;
	}
	return NO;
}

- (CGPoint)centerPoint {
	int i; 
	CGPoint centerPoint = {0,0};
	
	if (size <= 0) 
		return centerPoint;
	for (i = 0; i < size; i++) {
		centerPoint.x += hull[i].x;
		centerPoint.y += hull[i].y;
	}
	centerPoint.x = centerPoint.x / size;
	centerPoint.y = centerPoint.y / size;
	return centerPoint;
}

@synthesize size;
@synthesize hull;

- (void) dealloc {
	if (points) {
		free(points);
		points = 0;
	}
	if (hull) {
		free(hull);
		hull = 0;
	}
	[super dealloc];
}

@end

int PointComparison( const void* a, const void * b) {
	return (*((CGPoint**)a))->x - (*((CGPoint**)b))->x;
}

int IsRightTurn( CGPoint * p, CGPoint * q, CGPoint * r ) {
	float sum1 = q->x*r->y + p->x*q->y + r->x*p->y;
	float sum2 = q->x*p->y + r->x*q->y + p->x*r->y;

	float det = sum1 - sum2;

	if (det < 0)
		return 1;
	else
		return 0;
}

void ComputeConvexHull( CGPoint * points_in, int n, CGPoint * hull, int * hull_size ) {
	CGPoint **points, **upper, **lower;
	int i, j, nupper, nlower;

	// handle the degenerate case specially
	if (n < 2) {
		for (i=0; i<n; i++) {
			hull[i] = points_in[i];
		}
		*hull_size = n;
		return;
	}
	
	points = alloca(n * sizeof(CGPoint *));
	for (i=0; i<n; i++) {
		points[i] = points_in + i;
	}
	qsort(points,n,sizeof(CGPoint*),PointComparison);
	
	// find the upper half hull
	upper = alloca(n * sizeof(CGPoint *));
	upper[0] = points[0];
	upper[1] = points[1];
	nupper = 2;
	
	for (i = 2; i < n; i++) {
		upper[nupper++] = points[i];
		while (nupper > 2 && !IsRightTurn(upper[nupper-3],upper[nupper-2],upper[nupper-1])) {
			upper[nupper-2] = upper[nupper-1];
			nupper--;
		}
	}

	// reverse the index array to compute the lower half of the hull
	for (i=0, j=n-1; i<j; i++, j--) {
		CGPoint * t = points[i];
		points[i] = points[j];
		points[j] = t;
	}

	// find the lower half hull
	lower = alloca(n * sizeof(CGPoint *));
	lower[0] = points[0];
	lower[1] = points[1];
	nlower = 2;
	for (i = 2; i < n; i++) {
		lower[nlower++] = points[i];
		while (nlower > 2 && !IsRightTurn(lower[nlower-3],lower[nlower-2],lower[nlower-1])) {
			lower[nlower-2] = lower[nlower-1];
			nlower--;
		}
	}
	
	// combine the upper half hull with the lower half hull
	for (i = nupper, j = 1; i < n && j < nlower -1; i++, j++ ) {
		upper[i] = lower[j];
		nupper ++;
	}
	
	// output the hull data
	for (i=0; i<nupper; i++) {
		CGPoint * pt = upper[i];
		hull[i] = *pt;
	}
	*hull_size = nupper;
}
