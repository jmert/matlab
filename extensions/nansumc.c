/**
 * Compile this function with
 *
 *   mex -largeArrayDims CXXOPTIMFLAGS='-O -ftree-vectorize -funroll-loops -march=native' nansumc.c
 *
 * For even better performance, we can use a newer version of gcc
 * compiler, but it requires loading modules to compile.
 *
 *   # As of 2016 June 17:
 *   module load gcc/4.8.2-fasrc01
 *
 * 2016.06.17 (JBW) Caution: Using -O2 optimization caused the error handling
 *                  (mexErrMsgIdAndTxt) functions to abort rather than return
 *                  an error to the Matlab command prompt. I assume this was
 *                  due to an incompatible optimization pass, but I couldn't
 *                  identify which one it was.
 **/

#ifndef __has_builtin
#  define __has_builtin(x) 0
#endif
#if __has_builtin(__builtin_isnan) || __GNUC__ >= 4
#  define isnan(x) __builtin_isnan((x))
#else
#  include <math.h>
#endif

#include "mex.h"
#include "matrix.h"

double nansum(double *x, int N)
{
    double s;
    double v;
    int ii;

    s = 0.0;
    for (ii=0; ii<N; ++ii) {
        v = x[ii];
        s += isnan(v) ? 0.0 : v;
    }

    return s;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double* x;
    double  s = 0;
    int N;

    /***** Verify inputs *****/

    if (nrhs != 1)
    {
        mexErrMsgIdAndTxt("stats:nansumc:nrhs",
            "Only 1 input argument accepted.");
    }
    if (nlhs != 0 && nlhs != 1)
    {
        mexErrMsgIdAndTxt("stats:nansumc:nlhs",
            "No more than 1 output returned.");
    }

    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]))
    {
        mexErrMsgIdAndTxt("stats:nansumc:notDouble",
            "Input must be of type double.");
    }
    
    /**** Do the computation ****/

    if (mxIsSparse(prhs[0]))
    {
        int ncol = mxGetN(prhs[0]);
        mwIndex* cols = mxGetJc(prhs[0]);
        N = cols[ncol];
    }
    else
    {
        N = mxGetNumberOfElements(prhs[0]);
    }
    x = mxGetPr(prhs[0]);

 
    s = nansum(x, N);

    if (nlhs == 1) {
        plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
        ((double*)mxGetData(plhs[0]))[0] = s;
    }
}

