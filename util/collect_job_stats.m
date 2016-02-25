function collect_job_stats()
% collect_job_stats()
%
% Collects job information for the past day and stores the data in
% farmfiles/stats. The output can be later parsed and analyzed by
% summarize_job().
%

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

  % Filtering to show only past jobs requires a start time, so use yesterday.
  sttime = datestr(now()-1, 'yyyy-mm-ddTHH:MM:SS');
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

  % Split the new list by date:
  sn = strmatch('Start', fields, 'exact');
  todaystamp = floor(now());
  yesteridx = find(horzcat(info{:,sn}) < todaystamp);
  todayidx  = find(horzcat(info{:,sn}) > todaystamp);
  yesterinfo = info(yesteridx,:);
  todayinfo  = info(todayidx,:);

  if ~exist('farmfiles/stats','dir')
    system('mkdir -p farmfiles/stats');
  end

  % Load yesterday's statistics file and merge entries which are common:
  yesterfile = sprintf('farmfiles/stats/%s.mat', datestr(now()-1, 'yyyymmdd'));
  if exist_file(yesterfile)
    yesterdata = load(yesterfile);
  else
    yesterdata = struct();
    yesterdata.fields = fields;
    yesterdata.info = cell(0,nfields);
  end
  % Find the common intersecting IDs and replace with the newest info.
  cold = ismember(horzcat(yesterdata.info{:,id}), horzcat(yesterinfo{:,id}));
  cnew = ismember(horzcat(yesterinfo{:,id}), horzcat(yesterdata.info{:,id}));
  if any(cnew)
    yesterdata.info(cold,:) = yesterinfo(cnew,:);
  end
  % Then append any new entries
  if any(~cnew)
    yesterdata.info = vertcat(yesterdata.info, yesterinfo(~cnew,:));
  end
  % Sort by ID. Probably not all that useful, but it'll mirror output of
  % sacct if all info had been available at once.
  [dum,order] = sort(horzcat(yesterdata.info{:,id}));
  yesterdata.info = yesterdata.info(order,:);

  % Do the same for today's statistics:
  todayfile  = sprintf('farmfiles/stats/%s.mat', datestr(now(),   'yyyymmdd'));
  if exist_file(todayfile)
    todaydata = load(todayfile);
  else
    todaydata = struct();
    todaydata.fields = fields;
    todaydata.info = cell(0,nfields);
  end
  % Find the common intersecting IDs and replace with the newest info.
  cold = ismember(horzcat(todaydata.info{:,id}), horzcat(todayinfo{:,id}));
  cnew = ismember(horzcat(todayinfo{:,id}), horzcat(todaydata.info{:,id}));
  if any(cnew)
    todaydata.info(cold,:) = todayinfo(cnew,:);
  end
  % Then append any new entries
  if any(~cnew)
    todaydata.info = vertcat(todaydata.info, todayinfo(~cnew,:));
  end
  % Sort by ID. Probably not all that useful, but it'll mirror output of
  % sacct if all info had been available at once.
  [dum,order] = sort(horzcat(todaydata.info{:,id}));
  todaydata.info = todaydata.info(order,:);

  % Save data
  saveandtest(yesterfile, '-struct', 'yesterdata');
  saveandtest(todayfile,  '-struct', 'todaydata');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function jobid=parse_jobid(jobid)
  jobid = str2num(strrep(jobid,'.batch',''));
end

function datetime=parse_datetime(datetime)
  if strcmp(lower(datetime), 'unknown')
    datetime = NaN;
    return
  end
  datetime = datenum(datetime, 'yyyy-mm-ddTHH:MM:SS');
end

function tspan=parse_timespan(tspan)
  % May be empty if job is still running.
  if isempty(tspan)
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
