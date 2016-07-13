function latest=find_latest(reqdate, base, ext)
% latest=read_latest(reqdate, base, ext)
%
% Find the latest file which has a date suffix which occurs before the
% requsted date.
%
% INPUTS
%   reqdate    Date string as 'YYYYMMDD' or decimal integer YYYYMMDD
%              representing the bounding date.
%
%   base       Base name for the files to match.
%
%   ext        Defaults to '\.csv'; the file extension to ignore from the
%              suffix. Note that the period should be escaped for regular
%              expression syntax.
%
% RETURNS
%   data is the contents of the file, as returned by ParameterRead.
%

  if ~exist('reqdate','var'); reqdate = []; end
  if isempty(reqdate);        reqdate = datestr(now,'yyyymmdd'); end

  if ~exist('base','var'); base = []; end
  if isempty(base);        base = ''; end

  if ~exist('ext','var'); ext = [];      end
  if isempty(ext);        ext = '\.csv'; end

  if ischar(reqdate)
    reqdate = str2num(reqdate);
  end

  % List all matching files
  candids = dir(sprintf('%s*.csv',base));
  [path fname] = fileparts(base);
  % Filter the candidate list for exact matches to the form
  %     {base}YYYYMMDD.csv
  matches = regexp({candids(:).name}, ['^' fname '\d{8,8}' ext '$']);
  matches = cellfun(@(l) ~isempty(l), matches);
  candids = {candids(matches).name};

  % Get the dates for the remaining files
  dates = cellfun(@(c) str2num(c(end-11:end-4)), candids);
  % Again, filter for those occuring before the requested date
  candids = candids(dates <= reqdate);

  if ~isempty(candids)
    latest = fullfile(path, candids{end});
  else
    latest = [];
  end
end

