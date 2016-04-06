function [stats,fields,info]=summarize_job(jobregex,datebegin,dateend,doplot)
% [stats,fields,info]=summarize_job(jobregex,datebegin,dateend,doplot)
%
% Analyzes statistics recorded by collect_job_stats() for jobs matching
% jobregex within the given date range.
%
% INPUTS
%   jobregex     Regular expression used to filter by job names.
%
%   datebegin    Beginning search date as datenum or string parsable by
%                datenum().
%
%   dateend      Ending search date as datenum or string parsable by
%                datenum().
%
%   doplot       Show plots, true or false. Defaults to true for headed mode,
%                false for headless.
%
% OUTPUTS
%   stats        Struct containing job counts, max/avg for job resources,
%                and histograms for job resources.
%
%   fields       List of field headings for `info`.
%
%   info         Raw job information for the given job regex pattern.
%

  if ~exist('datebegin','var') || isempty(datebegin)
    datebegin = now() - 1;
  end
  if ~exist('dateend', 'var') || isempty(dateend)
    dateend = now();
  end
  if ~exist('doplot','var') || isempty(doplot)
    scr = get(0,'ScreenSize');
    if all(scr(3:4) == [1 1])
      doplot = false;
    else
      doplot = true;
    end
  end

  if ischar(datebegin)
    datebegin = datenum(datebegin);
  end
  if ischar(dateend)
    dateend = datenum(dateend);
  end

  datebegin = floor(datebegin);
  dateend = ceil(dateend+1/3600)-1;

  stats = struct();
  info = {};
  fields = {};
  for dd=datebegin:dateend
    datestamp = datestr(dd, 'yyyymmdd');
    statfile = sprintf('farmfiles/stats/%s.mat', datestamp);

    % Skip any date for which statistics aren't available.
    if ~exist_file(statfile)
      continue;
    end
    fprintf(1,'reading statistics for %s...\n', datestamp);
    xx = load(statfile);

    if isempty(fields)
      fields = xx.fields;
      jn = strmatch('JobName',fields, 'exact');
    end
    % Filter away all entries which don't match the given regular expression
    matches = ~cellfun(@isempty, regexp(xx.info(:,jn), jobregex));
    info = [info; xx.info(matches,:)];
  end
  if isempty(info)
    disp('No data to analyze.')
    return
  end

  sn = strmatch('State', fields, 'exact');
  % Mask for successfully completed jobs
  maskcd = rvec(strcmp('COMPLETED', info(:,sn)));
  % Mask for failed jobs
  maskf  = rvec(strcmp('FAILED', info(:,sn)));
  % Mask for timed-out jobs
  maskto = rvec(strcmp('TIMEOUT', info(:,sn)));

  stats.numcomplete = sum(maskcd);
  stats.numfail = sum(maskf);
  stats.numtimeout = sum(maskto);

  nn = strmatch('MaxVMSize', fields, 'exact');
  if ~isempty(nn)
    stats.memuse.avg = mean(horzcat(info{maskcd,nn}));
    stats.memuse.max = max(horzcat(info{maskcd,nn}));
    stats.memuse.used = sum(horzcat(info{maskcd,nn}));
    stats.memuse.wasted = sum(horzcat(info{maskf|maskto,nn}));

    % Find an even number of base-10 gigabytes to histogram across.
    gb = ceil(stats.memuse.max/1000)*1000;
    e = linspace(0, gb, 101);
    n = histc(horzcat(info{maskcd,nn}), e);
    stats.memuse.hist.e = e;
    stats.memuse.hist.n = n;

    if doplot
      figure()
      stairs(e, n);
      title(sprintf('Max memory use - %d jobs', stats.numcomplete))
      xlabel('Memory use [MiB]');
      ylabel('Counts');
    end
  end

  nn = strmatch('CPUTime', fields, 'exact');
  if ~isempty(nn)
    stats.timeuse.avg = mean(horzcat(info{maskcd,nn}));
    stats.timeuse.max = max(horzcat(info{maskcd,nn}));
    stats.timeuse.used = sum(horzcat(info{maskcd,nn}));
    stats.timeuse.wasted = sum(horzcat(info{maskf|maskto,nn}));

    % Find nearest quarter hour to histogram across.
    qhr = ceil(stats.timeuse.max/15)*15;
    e = linspace(0, qhr, 101);
    n = histc(horzcat(info{maskcd,nn}), e);
    stats.timeuse.hist.e = e;
    stats.timeuse.hist.n = n;

    if doplot
      figure()
      stairs(e, n);
      title(sprintf('Run times - %d jobs', stats.numcomplete))
      xlabel('Time elapsed [min]');
      ylabel('Counts');
    end
  end

  st = strmatch('Start', fields, 'exact');
  en = strmatch('End', fields, 'exact');
  if ~isempty(st) && ~isempty(en)
    % Determine the start and end times, rounded outward to an even 6 hours.
    stime = floor(min(horzcat(info{:,st}))*24/6)*6;
    etime = ceil(max(horzcat(info{:,en}))*24/6)*6;
    e = (stime:etime)/24;
    % Then build a histogram with 1-hour resolution:
    n = zeros(1, etime-stime+1);
    for ii=find(maskcd)
      % Round the individual job start and end time to the nearest hour.
      jobst = floor(info{ii,st}*24);
      joben = ceil(info{ii,en}*24);
      % Increment within that time span.
      n([jobst:joben]-stime+1) = n([jobst:joben]-stime+1) + 1;
    end

    stats.jobrate.max = max(n);
    stats.jobrate.hist.e = e;
    stats.jobrate.hist.n = n;

    if doplot
      figure()
      stairs(e, n);
      title('Running jobs per hour')
      xtics = get(gca(), 'xtick');
      xlabs = arrayfun(@(d) datestr(d,'HH:MM'), xtics, ...
          'UniformOutput',false);
      set(gca(), 'xticklabel', xlabs);
      xlabel(sprintf('Time, %s through %s', ...
          datestr(xtics(1), 'yyyy/mm/dd HH:MM'), ...
          datestr(xtics(end), 'yyyy/mm/dd HH:MM')))
      ylabel('Counts');
    end
  end

end

