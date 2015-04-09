//
//  ColorAllocator.m
//  Gesture
//
//  Created by Alan Pearson on 6/17/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#import "ColorAllocator.h"

#define COLORS 12

CGFloat colors[COLORS][4] = {

{ 1.0, 0.7, 0.7, 1.0 },
{ 0.7, 1.0, 0.7, 1.0 },
{ 0.7, 0.7, 1.0, 1.0 },

{ 0.5, 1.0, 1.0, 1.0 },
{ 1.0, 0.5, 1.0, 1.0 },
{ 1.0, 1.0, 0.5, 1.0 },

{ 0.8, 0.2, 0.2, 1.0 },
{ 0.2, 0.8, 0.2, 1.0 },
{ 0.2, 0.2, 0.8, 1.0 },

{ 1.0, 0.5, 0.1, 1.0 },
{ 0.1, 1.0, 0.5, 1.0 },
{ 0.5, 0.1, 1.0, 1.0 }

};


@implementation ColorAllocator

+ (ColorAllocator *) sharedInstance {
	static ColorAllocator* theInstance = nil;
	if (!theInstance) {
		theInstance = [[ColorAllocator alloc] init];
	}
	return theInstance;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		index = 0;
	}
	return self;
}

- (CGFloat *) nextColor {
	CGFloat * color = colors[index];
	index = (index + 1) % COLORS;
	return color;
}

@end
