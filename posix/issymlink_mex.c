#include <uchar.h>  /* Needed to define char16_t that Matlab wants */
#include <mex.h>
#include <matrix.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include <sys/stat.h>

/*
 * islink = issymlink_c(filename);
 */
void mexFunction(int nlhs, mxArray* plhs[],
                 int nrhs, const mxArray* prhs[])
{
    /* Inputs */
    char* fname = NULL;
    /* Outputs */
    /* Internal */
    int ret;
    struct stat status;

    /***** Verify inputs *****/

    if (nrhs != 1)
    {
        mexErrMsgIdAndTxt("util:issymlink_c:nrhs",
            "One input argument required.");
    }
    if (nlhs != 1)
    {
        mexErrMsgIdAndTxt("util:issymlink_c:nlhs",
            "One output argument required.");
    }

    if (!mxIsChar(prhs[0]))
    {
        mexErrMsgIdAndTxt("util:issymlink_c:notChar",
            "Input path must be of type char.");
    }

    fname = mxArrayToString(prhs[0]);
    ret = lstat(fname, &status);
    if (ret != 0) {
        char* reason = strerror(errno);
        mexErrMsgIdAndTxt("util:issymlink_c:syserr", "lstat: %s", reason);
    }
    plhs[0] = mxCreateLogicalScalar(S_ISLNK(status.st_mode));
    mxFree(fname);
}
