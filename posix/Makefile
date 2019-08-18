CC ?= gcc
CXX ?= g++
CFLAGS ?= -g -O3 -Wall
CXXFLAGS ?= -g -O3 -Wall

# When compatibility with R2014b and older is no longer necessary,
# the -DMEX_DOUBLE_HANDLE argument can be dropped.
#   https://www.mathworks.com/help/matlab/matlab_external/upgrade-mex-files-to-use-graphics-objects.html
MEX ?= mex
MEXFLAGS ?= -largeArrayDims -DMEX_DOUBLE_HANDLE

export FC
export MEX
export MEXFLAGS

.PHONY: clean

override CFLAGS += -std=gnu11 -fPIC -fno-exceptions
override CXXFLAGS += -std=gnu11 -fPIC

MEXCSRCS = $(wildcard *_mex.c)
MEXCXXSRCS = $(wildcard *_mex.cpp)
MEXFUNCS = $(MEXCSRCS:_mex.c=_c.mexa64) $(MEXCXXSRCS:_mex.cpp=_c.mexa64)

all: $(MEXFUNCS)

clean:
	rm -fr *.mex*

%_c.mexa64: %_mex.c Makefile
	$(MEX) $(MEXFLAGS) \
		CFLAGS='$$CFLAGS $(CFLAGS)' \
		LDFLAGS='$$LDFLAGS $(LDFLAGS)' \
		-output $@ $<

%_c.mexa64: %_mex.cpp Makefile
	$(MEX) $(MEXFLAGS) \
		CXXFLAGS='$$CXXFLAGS $(CXXFLAGS)' \
		LDFLAGS='$$LDFLAGS $(LDFLAGS)' \
		-output $@ $<
