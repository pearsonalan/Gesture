all: dist dist3d chull

GCC = /Xcode3.1.3/usr/bin/gcc-4.0
CFLAGS = -x c -arch i386 -fmessage-length=0 -std=c99 -Wno-trigraphs -fpascal-strings -fasm-blocks -O0 -Wreturn-type -Wunused-variable -isysroot /Xcode3.1.3/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -gdwarf-2 
LDFLAGS = -arch i386 -isysroot /Xcode3.1.3/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -framework CoreFoundation -framework ApplicationServices

chull: ConvexHull.o ConvexHullTest.o
	$(GCC) -o chull $(LDFLAGS) ConvexHull.o ConvexHullTest.o

ConvexHull.o: ConvexHull.c
	$(GCC) -c $(CFLAGS) -o ConvexHull.o ConvexHull.c 

ConvexHullTest.o: ConvexHullTest.c
	$(GCC) -c $(CFLAGS) -o ConvexHullTest.o ConvexHullTest.c 

dist: Distance.o
	$(GCC) -o dist $(LDFLAGS) Distance.o 

Distance.o: Distance.c
	$(GCC) -c $(CFLAGS) -o Distance.o Distance.c 

dist3d: Distance3d.o
	$(GCC) -o dist3d Distance3d.o

Distance3d.o: Distance3d.c
	$(GCC) -c -o Distance3d.o Distance3d.c
