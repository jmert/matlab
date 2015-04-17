function memtoc()
% memtoc()
%
% Prints malloc counter statistics to screen. See also memtic().
%

  [malloc,calloc,realloc] = trace_malloc_counts();

  fprintf(1, 'Used %dMB in new allocations and %dMB in reallocations\n', ...
    (malloc+calloc)/1024/1024, realloc/1024/1024);
end