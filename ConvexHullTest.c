#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#include "ConvexHull.h"
#include "ConvexHullTestData.h"

int main() {
	int inHull[12];
	
	ConvexHull(points1,inHull,NPOINTS1);
	ConvexHull(points2,inHull,NPOINTS2);
	
	return 0;
}