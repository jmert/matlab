function S = loadt(fname, varargin)
% S = loadt(fname, varargin)
%
% Wraps a call to load() with verbose printing of the filename while will
% be loaded and the time taken to perform the load.

  fprintf('loading %s... ', fname);
  tic()
  S = load(fname, varargin{:});
  toc()
end
