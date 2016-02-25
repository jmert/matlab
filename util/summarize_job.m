function stats=summarize_job(jobregex,datebegin,dateend)
% stats=summarize_job(jobregex,datebegin,dateend)
%
% Analyzes statistics recorded by collect_job_stats() for jobs matching
% jobregex within the given date range.
%
% INPUTS
%   jobregex     Regular expression used to filter by job names.
%
%   datebegin    Beginning search date as datenum or string parsable by
%                datenum().

%   dateend      Ending search date as datenum or string parsable by
%                datenum().
%
% OUTPUTS
%   stats        Struct containing job counts, max/avg for job resources,
%                and histograms for job resources.
%

  if ~exist('datebegin','var') || isempty(datebegin)
    datebegin = now() - 1;
  end
  if ~exist('dateend', 'var') || isempty(dateend)
    dateend = now();
  end
  if ischar(datebegin)
    datebegin = datenum(datebegin);
  end
  if ischar(datened)
    dateend = datenum(dateend);
  end

  datebegin = floor(datebegin);
  dateend = ceil(dateend)-1;

  % Column which contains JobName field
  jn = strmatch('JobName',xx.fields(:,1));

  info = {};
  for dd=datebegin:dateend
    datestamp = datestr(dd, 'yyyymmdd');
    statfile = sprintf('farmfiles/stats/%s.mat', datestamp);

    % Skip any date for which statistics aren't available.
    if ~exist_file(statfile)
      continue;
    end
    fprintf(1,'reading statistics for %s...\n', datestamp);
    xx = load(statfile);

    % Filter away all entries which don't match the given regular expression
    matches = ~cellfun(@isempty, regexp(xx.info(:,jn), jobregex));
    info = [info; xx.info(matches,:)];
  end

  stats = struct();

  sn = strmatch('State', xx.fields(:,1));
  % Mask for successfully completed jobs
  maskcd = rvec(strcmp('COMPLETED', xx.info(:,sn)));
  % Mask for failed jobs
  maskf  = rvec(strcmp('FAILED', xx.info(:,sn)));
  % Mask for timed-out jobs
  maskto = rvec(strcmp('TIMEOUT', xx.info(:,sn)));

  stats.numcomplete = sum(maskcd);
  stats.numfail = sum(maskf);
  stats.numtimeout = sum(maskto);

  nn = strmatch('MaxVMSize', xx.fields(:,1));
  if ~isempty(nn)
    stats.memuse.avg = mean(horzcat(xx.info{maskcd,nn}));
    stats.memuse.max = max(horzcat(xx.info{maskcd,nn}));

    % Find an even number of base-10 gigabytes to histogram across.
    gb = ceil(stats.memuse.max/1000)*1000;
    [bc,cnt] = hfill(horzcat(xx.info{maskcd,nn}), 100, 0, gb);
    stats.memuse.hist.bc = bc;
    stats.memuse.hist.n  = cnt;
  end

  nn = strmatch('Elapsed', xx.fields(:,1));
  if ~isempty(nn)
    stats.timeuse.avg = mean(horzcat(xx.info{maskcd,nn}));
    stats.timeuse.max = max(horzcat(xx.info{maskcd,nn}));

    % Find nearest quarter hour to histogram across.
    qhr = ceil(stats.timeuse.max/15)*15;
    [bc,cnt] = hfill(horzcat(xx.info{maskcd,nn}), 100, 0, qhr);
    stats.timeuse.hist.bc = bc;
    stats.timeuse.hist.n  = cnt;
  end
end

