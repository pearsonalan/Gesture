#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#include <stdio.h>
#include <math.h>

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


    if (u < 0.0f || u > 1.0f)
        return 0;   // closest point does not fall within the line segment
 
    intersection.x = lineStart->x + u * ( lineEnd->x - lineStart->x );
    intersection.y = lineStart->y + u * ( lineEnd->y - lineStart->y );
 
    *dist = Magnitude( pt, &intersection );
 
    return 1;
}

void test(CGPoint *pt, CGPoint *lineStart, CGPoint *lineEnd) {
    float Distance;

	printf("Line (%.1f,%.1f) - (%.1f,%.1f), Point (%.1f,%.1f)\n",
    	lineStart->x, lineStart->y,
    	lineEnd->x,   lineEnd->y,
    	pt->x,		  pt->y
	);
	
    if (DistancePointLine( pt, lineStart, lineEnd, &Distance ) )
        printf( " - closest point falls within line segment, distance = %f\n", Distance );
    else
        printf( " - closest point does not fall within line segment\n" );
}

int main(void) {
    CGPoint LineStart, LineEnd, pt;

    LineStart.x = 10.0f; LineStart.y =  80.0f;
    LineEnd.x   = 10.0f; LineEnd.y   = -80.0f;
    pt.x        = 20.0f; pt.y        =  10.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =   3.0f; pt.y     =   70.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  100.0f; pt.y     =  80.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  100.0f; pt.y     =  80.00001f;
	test(&pt, &LineStart, &LineEnd);


    LineStart.x =  80.0f; LineStart.y =   2.0f;
    LineEnd.x   = -80.0f; LineEnd.y   =   2.0f;

    pt.x     =  20.0f; pt.y     =  10.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =   3.0f; pt.y     =   70.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  80.0f; pt.y     =  80.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  80.1f; pt.y     =  801.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  80.0f; pt.y     =  801.0f;
	test(&pt, &LineStart, &LineEnd);


    LineStart.x =  80.0f; LineStart.y =  -2.0f;
    LineEnd.x   = -80.0f; LineEnd.y   =   2.0f;

    pt.x     =  20.0f; pt.y     =  10.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =   3.0f; pt.y     =   70.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  80.0f; pt.y     =  80.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  80.1f; pt.y     =  801.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  80.0f; pt.y     =  801.0f;
	test(&pt, &LineStart, &LineEnd);


    LineStart.x =   0.0f; LineStart.y =   0.0f;
    LineEnd.x   = 100.0f; LineEnd.y   = 100.0f;

    pt.x     =  10.0f; pt.y     =  50.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  10.0f; pt.y     =  10.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  11.0f; pt.y     =  10.0f;
	test(&pt, &LineStart, &LineEnd);

    pt.x     =  110.0f; pt.y     =  90.0f;
	test(&pt, &LineStart, &LineEnd);
	return 0;
}
