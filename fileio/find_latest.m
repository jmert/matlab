function latest=find_latest(reqdate, base, ext)
% latest=find_latest(reqdate, base, ext)
%
% Find the latest file which has a date suffix which occurs before the
% requsted date.
%
% INPUTS
%   reqdate    Defaults to datestr(now(), 'yyyymmdd'). Date string as
%              'YYYYMMDD' or decimal integer YYYYMMDD representing the
%              bounding date.
%
%   base       Base name (optional path plus file name prefix) for the files
%              to match.
%
%   ext        Defaults to '.csv'; the file extension to ignore from the
%              suffix.
%
% RETURNS
%   latest     Path to the latest file consistent with the base naming.
%

  if ~exist('reqdate','var') || isempty(reqdate)
    reqdate = datestr(now,'yyyymmdd');
  end
  if ~exist('base','var') || isempty(base)
    base = '';
  end
  if ~exist('ext','var') || isempty(ext)
    ext = '.csv';
  end
  regext = strrep(ext, '.', '\.');

  if ischar(reqdate)
    reqdate = str2num(reqdate);
  end

  % List all matching files
  candids = dir(sprintf('%s*%s', base, ext));
  [path fname] = fileparts(base);
  % Filter the candidate list for exact matches to the form
  %     {base}YYYYMMDD{ext}
  matches = regexp({candids(:).name}, ['^' fname '\d{8,8}' regext '$']);
  matches = cellfun(@(l) ~isempty(l), matches);
  candids = {candids(matches).name};

  % Get the dates for the remaining files
  dates = cellfun(@(c) str2num(c(end-11:end-4)), candids);
  % Again, filter for those occuring before the requested date
  candids = candids(dates <= reqdate);

  % Guarantee ordering
  [dates,order] = sort(dates);
  candids = candids(order);

  if ~isempty(candids)
    latest = fullfile(path, candids{end});
  else
    latest = [];
  end
end

