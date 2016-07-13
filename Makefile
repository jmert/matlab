.PHONY: clean

all: \
	extensions/nansumc.mexa64

clean:
	find . -path .git -prune -o -iname '*.mex*' \
		-exec rm -fr {} \;

extensions/nansumc.mexa64: Makefile extensions/nansumc.c
	cd extensions; \
	mex -largeArrayDims \
		CXXOPTIMFLAGS='-O -ftree-vectorize -funroll-loops -march=native' \
		nansumc.c
