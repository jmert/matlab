function [is,ie]=trange(d,tstart,tend,fast,format)
% function trange(d,tstart,tend)
% 
% Searches d.t or d.ts for the indices corresponding closest to the given
% beginning and end times.
% 
% INPUTS
%   d         Standard TOD data structure
% 
%   tstart    Start time, either in string format recognizable by datenum() or
%             a decimal serial date.
% 
%   tend      End time, either in string format recognizable by datenum() or a
%             decimal serial date.
% 
%   fast      Optional, defaults to true. If true, d.t (fast times) are used,
%             otherwise use d.ts (slow times).
% 
%   format    Optional. If tstart and tend are strings and format is non-empty,
%             then format is used to provide a formatting hint to datenum().
% 
% OUTPUTS
%   is        Index into d.t/d.ts corresponding (most closely) to tstart.
% 
%   ie        Index into d.t/d.ts corresponding (most closely) to tend.
% 

  if ~exist('fast','var') || isempty(fast)
    fast = true;
  end

  if ~exist('format','var') || isempty(format)
    datevecfn = @datevec;
  else
    datevecfn = @(s) datevec(s, format);
  end

  % Then put times into MJD since that's what the pipeline uses. This requires
  % some ugly machinations since nothing seems to want to work with the
  % compatible types of time format...
  tstart = mat2cell(datevecfn(tstart), 1, [1 1 1 1 1 1]);
  tstart = date2mjd(tstart{:});
  tend = mat2cell(datevecfn(tend), 1, [1 1 1 1 1 1]);
  tend = date2mjd(tend{:});

  if fast
    field = 't';
  else
    field = 'ts';
  end

  is = binsearch(d.(field), tstart, false);
  ie = binsearch(d.(field), tend, false);

end