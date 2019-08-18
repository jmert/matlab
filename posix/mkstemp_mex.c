#include <uchar.h>  /* Needed to define char16_t that Matlab wants */
#include <mex.h>
#include <matrix.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <stdio.h>

/*
 * tmpfile = mkstemp_c(template);
 */
void mexFunction(int nlhs, mxArray* plhs[],
                 int nrhs, const mxArray* prhs[])
{
    /* Inputs */
    char* templ = NULL;
    /* Outputs */
    /* Internal */
    int fd;

    /***** Verify inputs *****/

    if (nrhs != 1)
    {
        mexErrMsgIdAndTxt("util:mkstemp_c:nrhs",
            "One input argument required.");
    }
    if (nlhs != 1)
    {
        mexErrMsgIdAndTxt("util:mkstemp_c:nlhs",
            "One output argument required.");
    }

    if (!mxIsChar(prhs[0]))
    {
        mexErrMsgIdAndTxt("util:mkstemp_c:notChar",
            "Input pattern must be of type char.");
    }

    templ = mxArrayToString(prhs[0]);
    fd = mkstemp(templ);
    if (fd == -1) {
        char* reason = strerror(errno);
        mexErrMsgIdAndTxt("util:mkstemp_c:syserr", "mkstemp: %s", reason);
    }
    plhs[0] = mxCreateString(templ);
    close(fd);
    mxFree(templ);
}
