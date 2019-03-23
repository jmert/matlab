# When compatibility with R2014b and older is no longer necessary,
# the -DMEX_DOUBLE_HANDLE argument can be dropped.
#   https://www.mathworks.com/help/matlab/matlab_external/upgrade-mex-files-to-use-graphics-objects.html
MEX ?= mex -DMEX_DOUBLE_HANDLE
MEXEXT ?= mexa64

MEX_CFLAGS += -Wall -std=gnu99
TARGETS := glob_c.$(MEXEXT)

.PHONY: clean

all: $(TARGETS)

%.$(MEXEXT): %.c | Makefile
	$(MEX) CFLAGS='$$CFLAGS $(MEX_CFLAGS)' $^

clean:
	rm -f $(TARGETS)
