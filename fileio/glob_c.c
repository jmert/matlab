#include <uchar.h>  /* Needed to define char16_t that Matlab wants */
#include <mex.h>
#include <matrix.h>
#include <errno.h>
#include <glob.h>
#include <string.h>

#include <stdio.h>

#ifdef GLOB_BRACE
/* These are not part of POSIX but rather are GNU extensions. */
#define MEX_GLOB_FLAGS (GLOB_BRACE | GLOB_TILDE | GLOB_TILDE_CHECK)
#else
#define MEX_GLOB_FLAGS 0
#endif

/* TODO
 * - Use GNU extensions to set custom opendir command.
 *
 *   A custom opendir() can allocate a much larger dirent buffer that readdir()
 *   will use to read file names into. glibc's version is relatively small and
 *   slows down greatly on very large directories.
 */

/*
 * files = glob_c(pattern);
 */
void mexFunction(int nlhs, mxArray* plhs[],
                 int nrhs, const mxArray* prhs[])
{
    /* Inputs */
    char* pat = NULL;
    /* Outputs */
    /* Internal */
    const int glob_flags = GLOB_MARK | MEX_GLOB_FLAGS;
    glob_t    glob_buf;
    int       ret;
    size_t    nfiles;

    /***** Verify inputs *****/

    if (nrhs != 1)
    {
        mexErrMsgIdAndTxt("util:glob_c:nrhs",
            "One input argument required.");
    }
    if (nlhs != 1)
    {
        mexErrMsgIdAndTxt("util:glob_c:nlhs",
            "One output argument required.");
    }

    if (!mxIsChar(prhs[0]))
    {
        mexErrMsgIdAndTxt("util:glob_c:notChar",
            "Input pattern must be of type char.");
    }

    pat = mxArrayToString(prhs[0]);
    ret = glob(pat, glob_flags, NULL, &glob_buf);
    if (ret != 0 && ret != GLOB_NOMATCH) {
        char* reason;
        switch (ret) {
            case GLOB_NOSPACE: reason = "GLOB_NOSPACE: Insufficent memory."; break;
            case GLOB_ABORTED: reason = "GLOB_ABORTED: Read error."; break;
            default:           reason = strerror(errno);
        }
        mexErrMsgIdAndTxt("util:glob_c:syserr", "glob: %s", reason);
    }

    nfiles = (ret == GLOB_NOMATCH) ? 0 : glob_buf.gl_pathc;
    plhs[0] = mxCreateCellMatrix(nfiles, 1);

    for (int ii=0; ii<nfiles; ++ii) {
        mxSetCell(plhs[0], ii, mxCreateString(glob_buf.gl_pathv[ii]));
    }

    mxFree(pat);
    globfree(&glob_buf);
}
