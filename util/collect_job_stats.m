function collect_job_stats()
% collect_job_stats()
%
% Collects job information for the past day and stores the data in
% farmfiles/stats. The output can be later parsed and analyzed by
% summarize_job().
%

  % In the first column, put a list of each field which we want sacct to
  % print out. In the second, a handler function can be registered to parse
  % the output of each field.
  fields = {...
      'JobID',     @parse_jobid; ...
      'JobName',   @char; ...
      'State',     @char;
      'Start',     @parse_datetime; ...
      'Elapsed',   @parse_timespan; ...
      'TimeLimit', @parse_timespan; ...
      'MaxVMSize', @parse_datasize; ...
      'ReqMem',    @parse_datasize; ...
      'ExitCode',  @char; ...
    };
  % Build a comma-separated list of all fields in order.
  fieldstr = sprintf('%s,', fields{:,1});
  fieldstr = fieldstr(1:end-1); % remove trailing comma
  nfields = size(fields,1);

  % Get the current user name:
  [r,user] = system_safe('whoami'); user = strtrim(user);

  % Filtering to show only past jobs requires a start time, so use yesterday.
  sttime = datestr(now()-1, 'yyyy-mm-ddTHH:MM:SS');
  sacctcmd = sprintf('sacct -nP --format="%s" -u %s -S "%s" -s CD,F,TO', ...
      fieldstr, user, sttime);
  filtcmd = 'tail -n +2';
  % Get output from sacct and split the data by fields
  [r,jobs] = system_safe([sacctcmd ' | ' filtcmd]);
  scanspec = repmat('%s', 1, nfields);
  jobs = textscan(jobs, scanspec, 'delimiter','|');

  % Pre-process all fields
  njobs = size(jobs{1},1);
  info = cell(njobs, nfields);
  for ii=1:nfields
    info(:,ii) = cellfun(fields{ii,2}, jobs{ii}, 'uniformoutput',false);
  end

  % Completed jobs end up being specified in two lines with the "batch" line
  % containing some of the information we want. We do a pass to merge all
  % adjascent entries that share a JobID and JobName contains 'batch'.
  id = strmatch('JobID', fields(:,1));
  jn = strmatch('JobName', fields(:,1));

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
  sn = strmatch('Start', fields(:,1));
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
  tspan = ((DD*24) + HH)*60 + MM + (SS/60);
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
