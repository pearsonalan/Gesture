//
//  GestureView.m
//  Gesture
//
//  Created by Alan Pearson on 6/9/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#import "GestureView.h"
#import "GestureViewController.h"
#import "Vector.h"
#import "ColorAllocator.h"

@implementation GestureView

- (id)init {
	self = [super init];
	if (self != nil) {
		//dprintf("init\n");
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		//dprintf("initWithFrame\n");
    }
    return self;
}

- (void)awakeFromNib {    
	//dprintf("awakeFromNib\n");
	diamondImage = [[UIImage imageNamed:@"diamond.png"] retain];
	positionButtonImage = [[UIImage imageNamed:@"position-button.png"] retain];	
}

- (void)drawPositionButton:(NSString*)buttonText atPoint:(CGPoint)p {
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGSize          shadowOffset = CGSizeMake(2, -2);
	float           shadowColorValues[] = {1, 0, 0, 1.0};
	CGColorRef      shadowColor;
	CGColorSpaceRef rgbColorSpace;
	
	CGContextSaveGState(context);
	rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	shadowColor = CGColorCreate(rgbColorSpace, shadowColorValues);
	CGContextSetShadowWithColor(context, shadowOffset, 5, shadowColor);
	CGContextSetLineWidth(context, 3.0);
	CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0);
	CGContextStrokeEllipseInRect(context, CGRectMake(p.x-15.0f, p.y-15.0f, 30.0f, 30.0f));
	CGColorRelease(shadowColor);
	CGColorSpaceRelease(rgbColorSpace);
	CGContextRestoreGState(context);

	CGImageRef positionButton = [positionButtonImage CGImage];
	CGContextDrawImage(context, CGRectMake(p.x-15.0f, p.y-15.0f, 30.0f, 30.0f), positionButton);
	
	CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f );
#if 0	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, p.x-5.0f, p.y); 
	CGContextAddLineToPoint(context, p.x+5.0f, p.y);
	CGContextMoveToPoint(context, p.x, p.y-5.0f); 
	CGContextAddLineToPoint(context, p.x, p.y+5.0f);
	CGContextDrawPath(context, kCGPathStroke);
#endif
	
	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
	UIFont * font = [UIFont fontWithName:@"Helvetica" size:16];
	CGSize textSize = [buttonText sizeWithFont:font];
	CGPoint textPoint = CGPointMake(p.x - textSize.width/2.0f, p.y - textSize.height/2.0f);
	[buttonText drawAtPoint:textPoint withFont:font];
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();

#if 1   // disable drawing the diamond background for now	
	CGRect r = [self frame];
	CGImageRef diamond = [diamondImage CGImage];
	CGContextSaveGState(context);
	CGContextScaleCTM(context, 1.0f, -1.0f);
	CGContextTranslateCTM(context, 0.0f, -r.size.height);
	CGContextDrawImage(context, r, diamond);
	CGContextRestoreGState(context);
#endif
	
	//[self drawPositionButton:@"1" atPoint:CGPointMake(60.0f, 60.0f)];
	//[self drawPositionButton:@"2" atPoint:CGPointMake(120.0f, 60.0f)];
	
	//dprintf("Drawing %d touches\n", [vectors count]);
	int vectorCount = 0;
	for (Stroke * group in [viewController strokes]) {
		[group drawRect:rect context:context];
		vectorCount += group.vectorCount;
	}

#if 0	
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	UIFont * font = [UIFont fontWithName:@"Helvetica" size:14];
	NSString * message = [NSString stringWithFormat:@"%d groups, %d vectors", [viewController strokes].count, vectorCount];
	CGPoint textPoint = CGPointMake(4, 0);
	[message drawAtPoint:textPoint withFont:font];
#endif

#if 0	
	PlayDescription * playDescription = [viewController playDescription];
	if (playDescription) {
		//[playDescription drawRect:rect context:context];
		
		CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
		UIFont * font = [UIFont fontWithName:@"Helvetica" size:14];
		NSString * message = [playDescription description];
		CGPoint textPoint = CGPointMake(4, 400);
		[message drawAtPoint:textPoint withFont:font];
	}
#endif	
}

- (void)dealloc {
    [super dealloc];
}

@end
