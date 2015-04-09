/*
 *  Geometry.c
 *  Gesture
 *
 *  Created by Alan Pearson on 6/11/09.
 *  Copyright 2009 Peekeez, Inc.. All rights reserved.
 *
 */

#include "Geometry.h"
#include "math.h"

float Magnitude( CGPoint *p1, CGPoint *p2 ) {
    CGPoint vec;
	
    vec.x = p2->x - p1->x;
    vec.y = p2->y - p1->y;
	
    return (float)sqrt( vec.x * vec.x + vec.y * vec.y );
}

int DistancePointLine( CGPoint *pt, CGPoint *lineStart, CGPoint *lineEnd, float *dist ) {
    float lineMag;
    float u;
    CGPoint intersection;
	
    lineMag = Magnitude( lineEnd, lineStart );
	
    u = ( ( ( pt->x - lineStart->x ) * ( lineEnd->x - lineStart->x ) ) +
		 ( ( pt->y - lineStart->y ) * ( lineEnd->y - lineStart->y ) ) ) /
	( lineMag * lineMag );
	
#if 0	
    if (u < 0.0f || u > 1.0f)
        return 0;   // closest point does not fall within the line segment
#endif
	
    intersection.x = lineStart->x + u * ( lineEnd->x - lineStart->x );
    intersection.y = lineStart->y + u * ( lineEnd->y - lineStart->y );
	
    *dist = Magnitude( pt, &intersection );
	
    return 1;
}
