function collect_job_stats()
% collect_job_stats()
%
% Collects job information for the past day and stores the data in
% farmfiles/stats. The output can be later parsed and analyzed by
% summarize_job().
%

  % Make sure we don't stall at a debug prompt if an error occurs:
  dbclear all
  try
    do_collection()
  catch ex
    fprintf(2, getReport(ex,'extended','hyperlinks','off'));
    exit(1)
  end

end

function do_collection()
  % In the first column, put a list of each field which should have a data
  % handler applied. The second column then is a function handle to a
  % function which will parse the input string.
  handlers = {...
      'AllocCPUS',        @str2double; ...
      'AllocNodes',       @str2double; ...
      'AssocID',          @str2double; ...
      'AveCPU',           @parse_timespan; ...
      'AveCPUFreq',       @parse_datasize; ...
      'AveDiskRead',      @parse_datasize; ...
      'AveDiskWrite',     @parse_datasize; ...
      'AvePages',         @str2double; ...
      'AveRSS',           @parse_datasize; ...
      'AveVMSize',        @parse_datasize; ...
      'ConsumedEnergy',   @str2double; ...
      'ConsumedEnergyRaw',@str2double; ...
      'CPUTime',          @parse_timespan; ...
      'CPUTimeRAW',       @str2double; ...
      'Elapsed',          @parse_timespan; ...
      'Eligible',         @parse_datetime; ...
      'End',              @parse_datetime; ...
      'GID',              @str2double; ...
      'JobID',            @parse_jobid; ...
      'JobIDRaw',         @parse_jobid; ...
      'MaxDiskRead',      @parse_datasize; ...
      'MaxDiskReadTask',  @str2double; ...
      'MaxDiskWrite',     @parse_datasize; ...
      'MaxDiskWriteTask', @str2double; ...
      'MaxPages',         @str2double; ...
      'MaxPagesTask',     @str2double; ...
      'MaxRSS',           @parse_datasize; ...
      'MaxRSSTask',       @str2double;
      'MaxVMSize',        @parse_datasize; ...
      'MaxVMSizeTask',    @str2double; ...
      'MinCPU',           @parse_timespan; ...
      'MinCPUTask',       @str2double; ...
      'NCPUS',            @str2double; ...
      'NNodes',           @str2double; ...
      'NTasks',           @str2double; ...
      'Priority',         @str2double; ...
      'QOSRaw',           @str2double; ...
      'ReqCPUFreq',       @parse_datasize; ...
      'ReqCPUFreqMin',    @parse_datasize; ...
      'ReqCPUFreqMax',    @parse_datasize; ...
      'ReqCPUFreqGov',    @parse_datasize; ...
      'ReqCPUS',          @str2double; ...
      'ReqMem',           @parse_datasize; ...
      'ReqNodes',         @str2double; ...
      'Reserved',         @parse_timespan; ...
      'ResvCPU',          @parse_timespan; ...
      'ResvCPURAW',       @str2double; ...
      'Start',            @parse_datetime; ...
      'Submit',           @parse_datetime; ...
      'Suspended',        @parse_timespan; ...
      'SystemCPU',        @parse_timespan; ...
      'Timelimit',        @parse_timespan; ...
      'TotalCPU',         @parse_timespan; ...
      'UID',              @str2double;
      'UserCPU',          @parse_timespan; ...
    };

  % Get the current user name:
  [r,user] = system_safe('whoami'); user = strtrim(user);

  % Filtering to show only past jobs requires a start time, so use last week.
  sttime = datestr(now()-7, 'yyyy-mm-ddTHH:MM:SS');
  sacctcmd = sprintf('sacct -P --format=ALL -u %s -S "%s" -s CD,F,TO', ...
      user, sttime);
  % Get output from sacct. Then parse the first line to get a list of headings.
  [r,jobs] = system_safe(sacctcmd);
  fields = textscan(jobs, '%s', 1);
  fields = regexp(fields{1}, '\|', 'split');
  fields = fields{1};
  nfields = numel(fields);
  scanspec = repmat('%s', 1, nfields);
  jobs = textscan(jobs, scanspec, 'delimiter','|', 'Headerlines',1);

  % Translate any fields which have a registered handler.
  njobs = size(jobs{1},1);
  info = cell(njobs, nfields);
  for ii=1:nfields
    nn = strmatch(fields{ii}, rvec(handlers(:,1)), 'exact');
    if ~isempty(nn)
      info(:,ii) = cellfun(handlers{nn,2}, jobs{ii}, 'uniformoutput',false);
    else
      info(:,ii) = jobs{ii};
    end
  end

  % Completed jobs end up being specified in two lines with the "batch" line
  % containing some of the information we want. We do a pass to merge all
  % adjascent entries that share a JobID and JobName contains 'batch'.
  id = strmatch('JobID', fields, 'exact');
  jn = strmatch('JobName', fields, 'exact');

  if size(info,1) > 0
    info2 = cell(size(info));
    info2(1,:) = info(1,:);
    cnt = 1;
    mergefields = setdiff(1:nfields, [id,jn]);
    for ii=2:njobs
      % Just collect the line if we don't need to merge.
      if info{ii,id} ~= info{ii-1,id} || ~strcmp(info{ii,jn},'batch')
        cnt = cnt + 1;
        info2(cnt,:) = info(ii,:);
        continue;
      end

      % Otherwise merge fields (in a type-specific way)
      for jj=mergefields
        switch class(info2{cnt,jj})
          case 'single'; condfn = @isnan;
          case 'double'; condfn = @isnan;
          case 'char'  ; condfn = @isempty;
        end
        if condfn(info2{cnt,jj}) && ~condfn(info{ii,jj})
          info2{cnt,jj} = info{ii,jj};
        end
      end
    end
    info = info2(1:cnt,:);
    clear info2;
  end % size(info,1) > 0

  if ~exist('farmfiles/stats','dir')
    system('mkdir -p farmfiles/stats');
  end

  % Enumerate which days are needed for all returned jobs. The sorting will
  % be done based on the submission time.
  su = strmatch('Submit', fields, 'exact');
  mindate = min(cell2mat(info(:,su)));
  maxdate = max(cell2mat(info(:,su)));

  % Merge data for all dates that have been retrieved.
  for dd=floor(mindate+eps()):ceil(maxdate-eps())
    datefile = sprintf('farmfiles/stats/%s.mat', datestr(dd, 'yyyymmdd'));
    if exist_file(datefile)
      datedata = load(datefile);
    else
      datedata = struct();
      datedata.fields = fields;
      datedata.info = cell(0,nfields);
    end

    % Identify sacct entries which we've just retrieved that belong to this
    % date range.
    datemask = (dd == floor(horzcat(info{:,su})+eps()));
    dateinfo = info(datemask,:);

    % Pre-empted and requeued jobs get a new submission time, so we want to
    % remove items from the stored data if a corresponding JobID no longer
    % matches the submission date for that job.
    otherinfo = info(~datemask,:);
    resub = ismember(horzcat(datedata.info{:,id}), horzcat(otherinfo{:,id}));
    % Cut down to non-resubmitted jobs.
    datedata.info = datedata.info(~resub,:);

    % Now for overlapping IDs, replace stored data with the newest info.
    cold = ismember(horzcat(datedata.info{:,id}), horzcat(dateinfo{:,id}));
    cnew = ismember(horzcat(dateinfo{:,id}), horzcat(datedata.info{:,id}));
    if any(cnew)
      datedata.info(cold,:) = dateinfo(cnew,:);
    end
    % Then append any new entries which haven't yet been stored.
    if any(~cnew)
      datedata.info = vertcat(datedata.info, dateinfo(~cnew,:));
    end
    % Sort by ID; probably not all that usefull, but it'll mirror out of
    % sacct as if all info had been available at once.
    [dum,order] = sort(horzcat(datedata.info{:,id}));
    datedata.info = datedata.info(order,:);

    % Save the data
    saveandtest(datefile, '-struct', 'datedata');
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function jobid=parse_jobid(jobid)
  jobid = str2num(strrep(jobid,'.batch',''));
end

function datetime=parse_datetime(datetime)
  if strcmp(lower(datetime), 'unknown') || strcmp(lower(datetime), 'invalid')
    datetime = NaN;
    return
  end
  datetime = datenum(datetime, 'yyyy-mm-ddTHH:MM:SS');
end

function tspan=parse_timespan(tspan)
  % May be empty if job is still running.
  if isempty(tspan) || strcmp(lower(tspan), 'invalid')
    tspan = NaN;
    return
  end
  % Look for fractional seconds at the end.
  nn = strfind(tspan, '.');
  MS = 0;
  if ~isempty(nn)
    MS = str2double(tspan(nn+1:end));
    % Strip off the fractional seconds
    tspan = tspan(1:nn-1);
  end
  % Seconds and minutes are always present
  SS = str2double(tspan(end-1:end));
  MM = str2double(tspan(end-4:end-3));
  HH = 0;
  DD = 0;
  % if elapsed is longer than 6 characters, then there must be an hour
  % specification.
  if numel(tspan) >= 7
    HH = str2double(tspan(end-7:end-6));
  end
  % Finally, a dash will indicate a number of days starts the spec.
  nn = strfind(tspan, '-');
  if ~isempty(nn)
    DD = str2double(tspan(1:nn));
  end
  % Translate everything into minutes.
  tspan = ((DD*24) + HH)*60 + MM + ((SS+MS)/60);
end

function dsize=parse_datasize(dsize)
  % Sizes returned in Megabytes (base 2)

  % May be empty if job is still running.
  if isempty(dsize)
    dsize = NaN;
    return
  end

  % Currently the framework can only deal with per-node memory allocations.
  % Do a sanity check to make sure we don't see a per-CPU spec.
  if dsize(end) == 'c'
    error('Per-CPU memory requests cannot be parsed.');
  end
  % Only the ReqMem field includes the n, so strip it off to make the rest of
  % the routine work generically for measured sizes as well.
  if dsize(end) == 'n';
    dsize = dsize(1:end-1);
  end
  val = str2double(dsize(1:end-1));
  suf = dsize(end);
  switch lower(suf)
    case 'k';
      val = val / 1024;
    case 'g'
      val = val * 1024;
  end
  dsize = val;
end
