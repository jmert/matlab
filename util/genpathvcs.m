function p=genpathvcs(d)
% p=genpathvcs(d)
%
% Like genpath(), but filters out common version control system (VCS)
% metadata directories.
%

  % Initialize return path.
  p = '';

  % Start analyzing given path. If dir() returns nothing, then the path
  % didn't exist, so do nothing.
  files = dir(d);
  if isempty(files)
    return
  end

  % Always at least add the given path.
  p = [p d pathsep()];

  % Then recursively deal with the all subdirectories.
  isdir = logical(horzcat(files.isdir));
  dirs = files(isdir);
  for ii=1:length(dirs)
    nm = dirs(ii).name;
    if ~strcmp(nm,'.') && ~strcmp(nm,'..') && ...      % self/parent
       ~strncmp(nm,'@',1) && ~strncmp(nm,'+',1) && ... % class/pkg dirs
       ~strcmp(nm,'CVS')  && ... % CVS
       ~strcmp(nm,'.svn') && ... % svn
       ~strcmp(nm,'.git') && ... % git
       ~strcmp(nm,'.hg')  && ... % mercurial
       ~strcmp(nm,'private')     % excluded in genpath()
      % Recursively call on the unfiltered directories
      p = [p genpathvcs(fullfile(d,nm))];
    end
  end
end

