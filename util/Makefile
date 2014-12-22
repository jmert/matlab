.PHONY: clean

all: libtracemalloc.so trace_malloc_reset.mexa64 trace_malloc_counts.mexa64

clean:
	rm -fr libtracemalloc.so *.mexa64

libtracemalloc.so: Makefile trace_malloc.c trace_malloc.h
	g++ -Wall -O3 -fPIC -shared -ldl -o libtracemalloc.so trace_malloc.c

trace_malloc_reset.mexa64: Makefile trace_malloc.h trace_malloc_reset.c
	mex CFLAGS='$$CFLAGS -Wall' LDFLAGS='$$LDFLAGS -ldl' trace_malloc_reset.c

trace_malloc_counts.mexa64: Makefile trace_malloc.h trace_malloc_counts.c
	mex CFLAGS='$$CFLAGS -Wall' LDFLAGS='$$LDFLAGS -ldl' trace_malloc_counts.c
