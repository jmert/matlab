#define TRACE_MALLOC_COMPILE
#include "trace_malloc.h"

#ifdef __cplusplus
extern "C" {
#endif

#include <dlfcn.h>
#include <stdio.h>

/* Pointers glibc implementation */
typedef void* (*glibc_malloc_fn)(size_t);
typedef void* (*glibc_calloc_fn)(size_t, size_t);
typedef void* (*glibc_realloc_fn)(void*, size_t);
static glibc_malloc_fn  glibc_malloc  = NULL;
static glibc_calloc_fn  glibc_calloc  = NULL;
static glibc_realloc_fn glibc_realloc = NULL;

/* Internal counters */
static size_t malloc_bytes = 0;
static size_t calloc_bytes = 0;
static size_t realloc_bytes = 0;

/* Counter interface */
void trace_malloc_reset()
{
    malloc_bytes = 0;
    calloc_bytes = 0;
    realloc_bytes = 0;
}

void trace_malloc_counts(size_t* mbytes, size_t* cbytes, size_t* rbytes)
{
    *mbytes = malloc_bytes;
    *cbytes = calloc_bytes;
    *rbytes = realloc_bytes;
}

/* Initialize malloc family wrappers */
static void
trace_malloc_init(void)
{
    glibc_malloc = (glibc_malloc_fn)dlsym(RTLD_NEXT, "malloc");
    if (glibc_malloc == NULL)
    {
        fprintf(stderr, "Error in `dlsym`: %s\n", dlerror());
    }

    glibc_calloc = (glibc_calloc_fn)dlsym(RTLD_NEXT, "calloc");
    if (glibc_calloc == NULL)
    {
        fprintf(stderr, "Error in `dlsym`: %s\n", dlerror());
    }

    glibc_realloc = (glibc_realloc_fn)dlsym(RTLD_NEXT, "realloc");
    if (glibc_realloc == NULL)
    {
        fprintf(stderr, "Error in `dlsym`: %s\n", dlerror());
    }
}

void* malloc(size_t size)
{
    if (glibc_malloc == NULL)
    {
        trace_malloc_init();
    }

    malloc_bytes += size;

    return glibc_malloc(size);
}

/* Need a way to break cycle created by dlsym() calling calloc(). Use this
 * method as suggested by http://blog.bigpixel.ro/2010/09/interposing-calloc-on-linux/
 */
static void* null_calloc(size_t, size_t)
{
    return NULL;
}
void* calloc(size_t nmemb, size_t size)
{
    if (glibc_calloc == NULL)
    {
        /* Temporarily break the cycle */
        glibc_calloc = null_calloc;
        trace_malloc_init();
    }

    calloc_bytes += (nmemb * size);

    return glibc_calloc(nmemb, size);
}

void* realloc(void* ptr, size_t size)
{
    if (glibc_realloc == NULL)
    {
        trace_malloc_init();
    }

    realloc_bytes += size;

    return glibc_realloc(ptr, size);
}

#ifdef __cplusplus
}
#endif
