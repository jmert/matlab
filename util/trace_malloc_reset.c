#include "trace_malloc.h"
#include <dlfcn.h>
#include <mex.h>

void mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[])
{
  trace_malloc_reset_fn fnptr = NULL;
  fnptr = dlsym(RTLD_DEFAULT, "trace_malloc_reset");

  if (fnptr == NULL)
  {
    mexErrMsgIdAndTxt("trace_malloc:reset:dlsym",
        "Symbol `trace_malloc_reset` was not found. Did you remember to set LD_PRELOAD?");
  }

  fnptr();
}
