#include <stdio.h>
#include <math.h>

typedef struct tagXYZ
{
    float X, Y, Z;
}
XYZ;

float Magnitude( XYZ *Point1, XYZ *Point2 )
{
    XYZ Vector;

    Vector.X = Point2->X - Point1->X;
    Vector.Y = Point2->Y - Point1->Y;
    Vector.Z = Point2->Z - Point1->Z;

    return (float)sqrt( Vector.X * Vector.X + Vector.Y * Vector.Y + Vector.Z * Vector.Z );
}

int DistancePointLine( XYZ *Point, XYZ *LineStart, XYZ *LineEnd, float *Distance )
{
    float LineMag;
    float U;
    XYZ Intersection;
 
    LineMag = Magnitude( LineEnd, LineStart );
 
    U = ( ( ( Point->X - LineStart->X ) * ( LineEnd->X - LineStart->X ) ) +
        ( ( Point->Y - LineStart->Y ) * ( LineEnd->Y - LineStart->Y ) ) +
        ( ( Point->Z - LineStart->Z ) * ( LineEnd->Z - LineStart->Z ) ) ) /
        ( LineMag * LineMag );
 
    if( U < 0.0f || U > 1.0f )
        return 0;   // closest point does not fall within the line segment
 
    Intersection.X = LineStart->X + U * ( LineEnd->X - LineStart->X );
    Intersection.Y = LineStart->Y + U * ( LineEnd->Y - LineStart->Y );
    Intersection.Z = LineStart->Z + U * ( LineEnd->Z - LineStart->Z );
 
    *Distance = Magnitude( Point, &Intersection );
 
    return 1;
}

int main( void )
{
    XYZ LineStart, LineEnd, Point;
    float Distance;


    LineStart.X =  50.0f; LineStart.Y =   80.0f; LineStart.Z =  300.0f;
    LineEnd.X   =  50.0f; LineEnd.Y   = -800.0f; LineEnd.Z   = 1000.0f;
    Point.X     =  20.0f; Point.Y     = 1000.0f; Point.Z     =  400.0f;

    if( DistancePointLine( &Point, &LineStart, &LineEnd, &Distance ) )
        printf( "closest point falls within line segment, distance = %f\n", Distance );
    else
        printf( "closest point does not fall within line segment\n" );


    LineStart.X =  0.0f; LineStart.Y =   0.0f; LineStart.Z =  50.0f;
    LineEnd.X   =  0.0f; LineEnd.Y   =   0.0f; LineEnd.Z   = -50.0f;
    Point.X     = 10.0f; Point.Y     =  50.0f; Point.Z     =  10.0f;

    if( DistancePointLine( &Point, &LineStart, &LineEnd, &Distance ) )
        printf( "closest point falls within line segment, distance = %f\n", Distance );
    else
        printf( "closest point does not fall within line segment\n" );

	return 0;
}
