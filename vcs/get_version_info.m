function vid=get_version_info(func,base,target)
% vid=get_version_info(func,base,target)
%
% If the calling function is stored in a SCM, then return a version structure
% which identifies the current snapshot of the SCM (if possible).
%
% INPUTS
%   func    Optional, defaults to []. Specifies how to search for repository
%           information:
%
%             1. If empty, the call stack is traversed to get the caller's
%                information. The folder which contains the source for the
%                calling function is searched for repository information. If
%                called from the REPL, then the current working directory is
%                used instead.
%
%             2. If func is a function handle, the source path for the function
%                is searched. Using a function handle to an anonymous function
%                is an error.
%
%             3. If func is a string, then it must be a valid path, and that
%                path will be searched for repository information. It is an
%                error if the path does not exist.
%
%   base    Optional, defaults to 'master'. Specifies the "revision 0" tag or
%           branch point.
%
%   target  Optional, defaults to 'HEAD'. Specifies the target tag or branch
%           to use as the destination revision.
%
% OUTPUT
%   vid     The version structure
%
% SUPPORTED TYPES
%
%   Git
%
% REQUIREMENTS
%
%   - Unix utility 'which' is used to identify whether a particular SCM program
%     is installed on the current host.
%
% NOTES
%
%   CVS is *NOT* supported since even accessing the log may require an
%   authentication to the repository server. Also, the repository does
%   not carry a global revision ID but instead for only a single file, so
%   getting a consistent code state is difficult with only the file revision
%   ID.
%

  persistent vid_persist

  if ~exist('func','var') || isempty(func)
    st = dbstack('-completenames');
    % Get the path of the parent function. The current function is index 1 in
    % the stack trace, so 2 is the parent. If the length is less than 2, then
    % use the current working directory since we must have been called by the
    % user interactively.
    if length(st) < 2
      func = pwd();
    else
      func = st(2).file;
    end
  end

  if ~exist('base','var') || isempty(base)
    base = 'master';
  end

  if ~exist('target','var') || isempty(target)
    target = 'HEAD';
  end

  if isa(func, 'function_handle')
    finfo = functions(func);
    % Anonymous functions have no path, so throw an error
    if isempty(finfo.file)
      error('get_version_id:AnonymousFunction', ...
          'func cannot be an anonymous function');
    end
    [parentpath,dum,dum] = fileparts(finfo.file);

  elseif ischar(func)
    if exist(func, 'file')
      [func,dum,dum] = fileparts(func);
    end
    if ~exist(func, 'dir')
      error('get_version_id:NonexistentPath', ...
        'Path ''%func'' not found.', func)
    end
    parentpath = func;
  end

  % Avoid all the following work if we've already figured this out once and
  % cached the answer.
  if isempty(vid_persist)
    vid_persist = containers.Map();
  end

  persist_key = [parentpath ':' base '..' target];
  if isKey(vid_persist, persist_key)
    vid = vid_persist(persist_key);
    return
  end

  vid = struct();
  vid.revs = {base, target};
  vid.rev_ids = {'',''};
  vid.rev_count = 0;
  vid.is_dirty = false;

  % First identify whether the particular SCM type can be queried at all since
  % the application may not be available in some environments.
  [bingit,gitpath] = unix('which git 2>/dev/null');
  havegit = (bingit == 0);

  if ~havegit
    error('get_version_id:NoVCS', 'No useable VCS was found')
  end

  % Change directories to the path of the file, saving the output to be
  % restored later since cd has global rather than function scope
  oldcwd = cd(parentpath);

  % Then also check which VCS metadata folder actually exist
  %
  % git and Mercurial only place a .git and .hg folder respectively at the top
  % of the repository, so a simple directory check won't do. Instead just run
  % the commands and checking for return status.
  gitret = 1;
  if havegit
    [gitret,s] = unix('git rev-parse >/dev/null 2>&1');
  end
  gitrepo = (gitret == 0);

  % Then get an identifier for each SCM if applicable. There is some variation
  % in formatting since no tool provides exactly the same output.
  if gitrepo
    % Get the SHA1 hashes for each of the chosen references
    [r,str] = unix(['stty -echo; git rev-parse ' base]);
    if r ~= 0
      error('get_version_info:UnknownRevision', ...
          'Revsion ''%s'' is unknown', base);
    end
    vid.rev_ids{1} = strtrim(str);
    [r,str] = unix(['stty -echo; git rev-parse ' target]);
    if r ~= 0
      error('get_version_info:UnknownRevision', ...
          'Revsion ''%s'' is unknown', target);
    end
    vid.rev_ids{2} = strtrim(str);

    % Then because the references may actually be on different branches, use
    % the latest common ancestor as reference point to start counting the
    % number of revisions to the target.
    [r,str] = unix(['stty -echo; git merge-base ' vid.rev_ids{1} ...
        ' ' vid.rev_ids{2} ' 2>/dev/null']);
    ref = strtrim(str);

    % Then actually get the number of commits.
    [r,str] = unix(['stty -echo; git rev-list --count ' vid.rev_ids{2} ...
        ' ^' vid.rev_ids{1} ' 2>/dev/null']);
    vid.rev_count = str2double(strtrim(str));

    % Finally, store a field that describes if the code directory contains
    % uncommitted changes.
    [r,str] = unix(['stty -echo; git describe --always --dirty']);
    str = strtrim(str);
    vid.is_dirty = strcmp(str(end-4:end), 'dirty');
  end

  % Restore the current working directory to its previous state before exiting
  cd(oldcwd);

  % Store a copy so we don't have to do this again.
  vid_persist(persist_key) = vid;
end

