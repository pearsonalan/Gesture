//
//  ColorAllocator.h
//  Gesture
//
//  Created by Alan Pearson on 6/17/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#import "Gesture.h"


@interface ColorAllocator : NSObject {
	int index;
}
+ (ColorAllocator *) sharedInstance;
- (CGFloat *) nextColor;
@end
