function revid=get_rev_id(func)
% revid=get_rev_id(func)
%
% If the calling function is stored in a SCM, then return a string which
% identifies the current snapshot of the SCM (if possible).
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
% OUTPUT
%   revid   The identifying string if in an SCM, empty otherwise.
%
% SUPPORTED TYPES
%
%   Git
%   Mercurial
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

  % 
  if ~exist('func','var') || isempty(func)
    st = dbstack('-completenames');
    % Get the path of the parent function. The current function is index 1 in
    % the stack trace, so 2 is the parent. If the length is less than 2, then
    % use the current working directory since we must have been called by the
    % user interactively.
    if length(st) < 2
      parentpath = pwd();
    else
      [parentpath,parentname,parentext] = fileparts(st(2).file);
    end

  elseif isa(func, 'function_handle')
    finfo = functions(func);
    % Anonymous functions have no path, so throw an error
    if isempty(finfo.file)
      error('get_rev_id:AnonymousFunction', ...
          'func cannot be an anonymous function');
    end
    [parentpath,parentname,parentext] = fileparts(finfo.file);

  elseif ischar(func)
    if ~exist(func, 'dir')
      error('get_rev_id:NonexistentPath', ...
        'Path not found.')
    end
    parentpath = func;
  end

  % Change directories to the path of the file, saving the output to be
  % restored later since cd has global rather than function scope
  oldcwd = cd(parentpath);

  % First identify whether the particular SCM type can be queried at all since
  % the application may not be available in some environments.
  [bingit,gitpath] = unix('which git 2>/dev/null');
  [binhg, hgpath]  = unix('which hg  2>/dev/null');
  havegit = (bingit == 0);
  havehg  = (binhg  == 0);

  % Then also check which SCM metadata folder actually exist
  %
  % git and Mercurial only place a .git and .hg folder respectively at the top
  % of the repository, so a simple directory check won't do. Instead just run
  % the commands and checking for return status.
  gitret = 1; hgret = 1;
  if havegit
    [gitret,s] = unix('git rev-parse >/dev/null 2>&1');
  end
  if havehg
    % For some odd reason, failing to find an HG repo here causes either Matlab
    % or bash (not sure which) to emit a warning about aborting with signal 127
    % (which was being printed to screen despite the redirects to /dev/null).
    % Finally came upon the following '&& true || false' statement which
    % alleviates the problem.
    [hgret,s] = unix('hg root >/dev/null 2>&1 && true || false');
  end
  gitrepo = (gitret == 0);
  hgrepo  = (hgret  == 0);

  % Set defaults just in case neither case are executed
  prefix = [];
  str    = [];
  % Then get an identifier for each SCM if applicable. There is some variation
  % in formatting since no tool provides exactly the same output.
  if     havegit && gitrepo
    prefix = 'git: ';
    [r,str] = unix(['stty -echo; echo "$(git describe --abbrev=12 ' ...
        '--always --dirty) $(git branch | egrep ''^*'' | cut -d'' '' -f2)"']);
  elseif havehg  && hgrepo
    prefix = 'hg: ';
    [r,str] = unix('stty -echo; hg id -ib');
  end
  % Make revid identify both the SCM and a revision ID. The (1:end-1) removes
  % the extra carriage return captured by the unix command calls.
  revid = [prefix str(1:end-1)];

  % Restore the current working directory to its previous state before exiting
  cd(oldcwd);
end

