#include <mex.h>
#include <dlfcn.h>
#include <limits.h>
#include "trace_malloc.h"

void mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[])
{
  trace_malloc_counts_fn fnptr = NULL;
  size_t malloc_bytes;
  size_t calloc_bytes;
  size_t realloc_bytes;

  if (nlhs != 3)
  {
    mexErrMsgIdAndTxt("trace_malloc:counts:nlhs",
        "Three output arguments required.");
  }

  fnptr = dlsym(RTLD_DEFAULT, "trace_malloc_counts");
  if (fnptr == NULL)
  {
    mexErrMsgIdAndTxt("trace_malloc:counts:dlsym",
        "Symbol `trace_malloc_counts` was not found. Did you remember to set LD_PRELOAD?");
  }

  fnptr(&malloc_bytes, &calloc_bytes, &realloc_bytes);

  plhs[0] = mxCreateDoubleScalar((double)malloc_bytes); 
  plhs[1] = mxCreateDoubleScalar((double)calloc_bytes); 
  plhs[2] = mxCreateDoubleScalar((double)realloc_bytes);
}
