/*
 *  Geometry.h
 *  Gesture
 *
 *  Created by Alan Pearson on 6/11/09.
 *  Copyright 2009 Peekeez, Inc.. All rights reserved.
 *
 */

#import <CoreGraphics/CoreGraphics.h>

float Magnitude( CGPoint *p1, CGPoint *p2 ) ;
int DistancePointLine( CGPoint *pt, CGPoint *lineStart, CGPoint *lineEnd, float *dist ) ;
