function make_taxis(t,n,fmt)
% make_taxis(t,n,fmt)
%
% Modifies the current active x-axis to show the times as formatted strings.
%
% INPUTS
%   t      Time series for corresponding plotted data. Should be in MJD form.
%
%   n      Optional. Number of ticks to place along the axis. If not set or
%          empty, then the current number of tick marks is used.
%
%   fmt    Optional. A function handle to a string formatting function which
%          takes 6 parameters (year, month, day, hour, minute, sec) as
%          integers and returns a formatted string. Defaults to
%
%              @(yr,mon,day,hr,min,sec) sprintf('%02i:%02i', hr, min)
%
% EXAMPLE
%
%   plot(d.t, d.eloff);
%   make_taxis(gca(), d.t, 10)
%

  if ~exist('n','var') || isempty(n)
    n = length(get(gca(), 'xtick'));
  end
  ticks = floor(linspace(1,length(t),n));

  if ~exist('fmt','var') || isempty(fmt)
    fmt = @(yr,mon,day,hr,min,sec) sprintf('%02i:%02i', hr, min);
  end

  [yr,mon,day,hr,min,sec] = mjd2date(t(ticks));
  tstr = arrayfun(fmt, yr, mon, day, hr, min, sec, 'uniformoutput', false);
  set(gca(), 'xtick', t(ticks), 'xticklabel', tstr);
  xlabel('UTC time')
end