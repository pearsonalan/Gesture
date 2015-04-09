//
//  Vector.m
//  Gesture
//
//  Created by Alan Pearson on 6/9/09.
//  Copyright 2009 Peekeez, Inc.. All rights reserved.
//

#import "Vector.h"
#import "Geometry.h"
#import "ConvexHull.h"
#import "ColorAllocator.h"

#define DRAW_STROKE_INFO 0

@interface Stroke (PrivateMethods)
- (void)segmentStroke ;
@end

//------------------------------------------------------------------------------
// Vector implementation
//

@implementation Vector

- (id) initWithStart:(CGPoint)s end:(CGPoint)e {
	self = [super init];
	if (self != nil) {
		start = s;
		end = e;
		angle = atan2f(end.y - start.y, end.x - start.x );
	}
	return self;
}

- (float) x {
	return end.x - start.x;
}

- (float) y {
	return end.y - start.y;
}

- (float) length {
	return Magnitude(&start,&end);
}


@synthesize start;
@synthesize end;
@synthesize angle;

@end

//------------------------------------------------------------------------------
// TouchVector implementation
//

@implementation TouchVector

- (id) initWithTouch:(UITouch*)touch inView:(UIView*)view {
	self = [super initWithStart:[touch previousLocationInView:view] end:[touch locationInView:view]];
	if (self != nil) {
		phase = [touch phase];
	}
	return self;
}

- (CGPoint)locationInView {
	return end;
}

- (CGPoint)previousLocationInView {
	return start;
}

@synthesize phase;

@end


//------------------------------------------------------------------------------
// Segment implementation
//

@implementation Segment

- (id) init {
	self = [super init];
	if (self != nil) {
		//dprintf("Creating segment %08x\n",self);
		vectors = [[NSMutableArray alloc] init];
		color = [[ColorAllocator sharedInstance] nextColor];
	}
	return self;
}

@synthesize start;
@synthesize end;
@synthesize vectors;

- (void)addVector:(Vector*)vec {
	//dprintf("Adding vector %08x to segment %08x\n",vec,self);
	if ([vectors count] == 0) {
		start = [vec start];
	}
	[vectors addObject:vec];
	end = [vec end];
}

- (void)drawRect:(CGRect)rect context:(CGContextRef)context {
	CGContextSetLineWidth(context,8.0);
	CGContextSetRGBStrokeColor(context, color[0], color[1], color[2], .5);
	CGContextSetRGBFillColor(context, color[0], color[1], color[2], .5);
	CGContextFillEllipseInRect(context, CGRectMake(start.x-10, start.y-10, 20, 20));
	for (Vector * vec in vectors) {
		CGContextBeginPath(context);
		CGContextMoveToPoint(context,vec.start.x,vec.start.y);
		CGContextAddLineToPoint(context,vec.end.x,vec.end.y);
		CGContextDrawPath(context, kCGPathStroke);
		CGContextFillEllipseInRect(context, CGRectMake(vec.end.x-10, vec.end.y-10, 20, 20));
	}
}


- (void) dealloc {
	[vectors release];
	[super dealloc];
}

@end


//------------------------------------------------------------------------------
// Stroke implementation
//
@implementation Stroke 

- (id) initWithColor:(CGFloat*)colorVec {
	self = [super init];
	if (self != nil) {
		touchVectors = [[NSMutableArray alloc] init];
		coalescedVectors = [[NSMutableArray alloc] init];
		segments = [[NSMutableArray alloc] init];
		color = colorVec;
		coalesced = NO;
		dprintf("Creating vector group with color: %0.1f, %0.1f, %0.1f, %0.1f\n", color[0], color[1], color[2], color[3]);
	}
	return self;
}


@synthesize start = startPoint;
@synthesize end = endPoint;

- (void) addTouchVector:(TouchVector*)vec {
	[touchVectors addObject:vec];
}

- (NSUInteger)vectorCount {
	return [touchVectors count];
}

- (TouchVector*)lastVector {
	if (!touchVectors || [touchVectors count] == 0) 
		return nil;
	return [touchVectors objectAtIndex:[touchVectors count]-1];
}

- (NSArray*)segments {
	return [[segments copy] autorelease];
}

- (NSArray*)vectors {
	return [[coalescedVectors copy] autorelease];
}

- (int)findSplitPointFrom:(int)start to:(int)end {
	if (start == end)
		return -1;
	
	TouchVector * startVec = [touchVectors objectAtIndex:start];
	TouchVector * endVec = [touchVectors objectAtIndex:end];
	//dprintf("phase of event %d is %d\n", 0, [startVec phase]);
	//dprintf("phase of event %d is %d\n", end-1, [endVec phase]);
	
	CGPoint spt = [startVec locationInView];
	CGPoint ept = [endVec locationInView];
	
	//dprintf("line = (%.1f,%.1f) - (%.1f,%.1f)\n",spt.x,spt.y,ept.x,ept.y);
	
	float maxDistance = 15.0;
	int split = -1;
	for (int i = start; i < end-1; i++) {
		TouchVector * v = [touchVectors objectAtIndex:i];
		CGPoint pt = [v locationInView];
		float distance;
		if (DistancePointLine(&pt, &spt, &ept, &distance)) {
			//dprintf("Compare vector %d (%.1f,%.1f) to line. distance = %.1f\n", i, pt.x, pt.y, distance);
			if (distance > maxDistance) {
				split = i;
				maxDistance = distance;
			}
		} else {
			//dprintf("Compare vector %d (%.1f,%.1f) to line. point outside of segment\n", i, pt.x, pt.y);
		}
	}
	
	if (split != -1) {
		//dprintf("Split point at %d, distance %.1f\n",split,maxDistance);
	}
	
	return split;
}

- (void)addVectorFrom:(CGPoint)spt to:(CGPoint)ept {
	Vector * vec = [[Vector alloc] initWithStart:spt end:ept];
	[coalescedVectors addObject:vec];
	[vec release];
}


- (void)coalesceVectorsFrom:(int)start to:(int)end {
	int splitIndex = [self findSplitPointFrom:start to:end];
	if (splitIndex == -1) {
		// cannot split this path
		TouchVector * startVec = [touchVectors objectAtIndex:start];
		TouchVector * endVec = [touchVectors objectAtIndex:end];
		
		CGPoint spt = [startVec locationInView];
		CGPoint ept = [endVec locationInView];
		
		float dist = Magnitude(&spt,&ept);
				
		dprintf("adding vector: #%d (%.1f,%.1f) - #%d (%.1f,%.1f) dist=%.1f\n",start,spt.x,spt.y,end,ept.x,ept.y,dist);
		[self addVectorFrom:spt to:ept];
	} else {
		dprintf("coalescing from %d to %d: split at %d\n", start, end, splitIndex);
		
		[self coalesceVectorsFrom:start to:splitIndex];
		[self coalesceVectorsFrom:splitIndex to:end];
	}
}

- (void)coalesceVectors {
	int c = [touchVectors count];
	
	TouchVector * startVec = [touchVectors objectAtIndex:0];
	TouchVector * endVec = [touchVectors objectAtIndex:c-1];
	
	startPoint = [startVec locationInView];
	endPoint = [endVec locationInView];
	
	dprintf("Coalescing %d touch events\n", c);
	
	if (c <= 1) {
		return;
	}

	[self coalesceVectorsFrom:0 to:c-1];
	coalesced = YES;
	
	[self segmentStroke];
}

// go through all of the vectors in the stroke.  Split them into different segments at points where the angle is greater
// than some threashold.  We actually use the cosine of the angle, which is achievable through the dot-product rather
// than the actual angle
#define CONTINUATION_THREASHOLD	0.5f
- (void)segmentStroke {
	int i = 0;
	Vector * vecPrev = nil;
	//dprintf("Begin Segment Stroke\n");
	Segment * currentSegment = [[Segment alloc] init];
	[segments addObject:currentSegment];
	for (Vector * vec in coalescedVectors) {
		
		// if there is a previous vector, see if the angle in between them separates them into different segments
		if (vecPrev) {
			float cos_angle = (vecPrev.x * vec.x + vecPrev.y * vec.y) / (sqrt(vecPrev.x * vecPrev.x + vecPrev.y * vecPrev.y) * sqrt(vec.x * vec.x + vec.y * vec.y));
			//float angle = vecPrev.angle - vec.angle;
			//dprintf(" compare vector %d to vector %d.  cos_angle = %.3f, angle = %.3f rad, %.1f deg\n",  i,i-1,cos_angle, angle, angle * 180.0 / M_PI);
			if (cos_angle < CONTINUATION_THREASHOLD) {
				//dprintf("Segment break\n");
				[currentSegment release];
				currentSegment = [[Segment alloc] init];
				[segments addObject:currentSegment];
			}
		}
		
		// add the vector to the current segment
		[currentSegment addVector:vec];
		
		vecPrev = vec;
		i++;
	}
	[currentSegment release];
	//dprintf("End Segment Stroke\n");
}


- (void)drawRect:(CGRect)rect context:(CGContextRef)context {
#if DRAW_STROKE_INFO
	for (Segment * seg in segments) {
		[seg drawRect:rect context:context];
	}
	
	CGContextSetLineWidth(context,2.0);
	CGContextSetRGBStrokeColor(context, color[0], color[1], color[2], color[3]);
	CGContextSetRGBFillColor(context, color[0], color[1], color[2], color[3]);
	
	for (TouchVector * vector in touchVectors) {
		CGContextSaveGState(context);
		switch ([vector phase]) {
			case UITouchPhaseBegan:
				CGContextTranslateCTM(context,vector.locationInView.x,vector.locationInView.y);
				CGContextFillEllipseInRect(context, CGRectMake(-4, -4, 8, 8));
				break;
				
			case UITouchPhaseMoved:
				CGContextBeginPath(context);
				CGContextMoveToPoint(context,vector.previousLocationInView.x,vector.previousLocationInView.y); 
				CGContextAddLineToPoint(context,vector.locationInView.x,vector.locationInView.y); 
				CGContextDrawPath(context, kCGPathStroke);
				
				CGContextTranslateCTM(context,vector.locationInView.x,vector.locationInView.y);
				CGContextRotateCTM(context,vector.angle);
				
				CGContextBeginPath(context);
				CGContextMoveToPoint(context,-6,-3);
				CGContextAddLineToPoint(context,0,0);
				CGContextAddLineToPoint(context,-6,3);
				CGContextDrawPath(context, kCGPathStroke);
				break;
			case UITouchPhaseEnded:
				CGContextBeginPath(context);
				CGContextMoveToPoint(context,vector.previousLocationInView.x,vector.previousLocationInView.y); 
				CGContextAddLineToPoint(context,vector.locationInView.x,vector.locationInView.y); 
				CGContextDrawPath(context, kCGPathStroke);
				break;
		}
		CGContextRestoreGState(context);
	}

	if (coalesced) {
		UIFont * font = [UIFont fontWithName:@"Helvetica" size:10];
		
		Vector * vecPrev = nil;
		for (Vector * vec in coalescedVectors) {
			if (vecPrev) {
				float cos_angle = (vecPrev.x * vec.x + vecPrev.y * vec.y) / (sqrt(vecPrev.x * vecPrev.x + vecPrev.y * vecPrev.y) * sqrt(vec.x * vec.x + vec.y * vec.y));
				float angle = M_PI - vecPrev.angle + vec.angle;
				
				CGContextSetRGBFillColor(context, 0.3, 0.3, 0.3, 0.6);
				
				NSString * cosText = [NSString stringWithFormat:@"%.3f", cos_angle];
				NSString * angleText = [NSString stringWithFormat:@"%.3f", angle];
				
				CGSize cosTextSize = [cosText sizeWithFont:font];
				CGSize angleTextSize = [angleText sizeWithFont:font];
				
				CGContextFillRect(context, CGRectMake(vec.start.x+5, vec.start.y - 15, MAX(cosTextSize.width,angleTextSize.width) + 10, 30));
				
				CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
				CGPoint textPoint = CGPointMake(vec.start.x + 10, vec.start.y - 12);
				[cosText drawAtPoint:textPoint withFont:font];
				textPoint = CGPointMake(vec.start.x + 10, vec.start.y - 2);
				[angleText drawAtPoint:textPoint withFont:font];
			}
			
			vecPrev = vec;
		}
	}		

#else	
	
	CGContextSetLineWidth(context,4.0);
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	
	CGContextBeginPath(context);
	
	for (TouchVector * vector in touchVectors) {
		switch ([vector phase]) {
			case UITouchPhaseBegan:
				CGContextFillEllipseInRect(context, CGRectMake(vector.locationInView.x-4, vector.locationInView.y-4, 8, 8));
				break;
				
			case UITouchPhaseMoved:
				CGContextMoveToPoint(context,vector.previousLocationInView.x,vector.previousLocationInView.y); 
				CGContextAddLineToPoint(context,vector.locationInView.x,vector.locationInView.y); 
				break;
				
			case UITouchPhaseEnded:
				CGContextMoveToPoint(context,vector.previousLocationInView.x,vector.previousLocationInView.y); 
				CGContextAddLineToPoint(context,vector.locationInView.x,vector.locationInView.y); 
				break;
		}
	}
	
	CGContextDrawPath(context, kCGPathStroke);
	
	
#endif	
	
}

- (void) dealloc {
	[touchVectors release];
	[coalescedVectors release];
	[segments release];
	[super dealloc];
}


@end