#ifndef TRACE_MALLOC_H
#define TRACE_MALLOC_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _GNU_SOURCE
#    define _GNU_SOURCE
#endif

#ifdef TRACE_MALLOC_COMPILE
#    define EXTERN
#else
#    define EXTERN extern
#endif

#include <stddef.h>

EXTERN void trace_malloc_reset(void);
EXTERN void trace_malloc_counts(size_t* malloc_bytes, size_t* calloc_bytes,
    size_t* realloc_bytes);

typedef void (*trace_malloc_reset_fn)(void);
typedef void (*trace_malloc_counts_fn)(size_t* malloc_bytes,
    size_t* calloc_bytes, size_t* realloc_bytes);

#ifdef __cplusplus
}
#endif

#endif