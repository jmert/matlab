function revid=get_rev_id()
%revid=get_rev_id
%
%If the calling function is stored in a SCM, then return a string which
%identifies the current snapshot of the SCM (if possible).
%
%INPUTS
%  None
%
%OUTPUT
%  revid   The identifying string if in an SCM, empty otherwise.
%
%SUPPORTED TYPES
%
%  Git
%  Mercurial
%
%NOTES
%
%  CVS is *NOT* supported since even accessing the log may require an
%  authentication to the repository server.
%

  % Get the path of the parent function. The current function is index 1 in the
  % stack trace, so 2 is the parent. If the length is less than 2, then just
  % return an empty string since we must have been called directly by the user
  % interactively.
  st = dbstack('-completenames');
  if length(st) < 2
    return
  end
  [parentpath,parentname,parentext] = fileparts(st(2).file);
  fname = [parentname,parentext];
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
    [r,str] = unix('git describe --all --long');
  elseif havehg  && hgrepo
    prefix = 'hg: ';
    % For some odd reason, 
    [r,str] = unix('hg id -inb');
  end
  % Make revid identify both the SCM and a revision ID. The (1:end-1) removes
  % the extra carriage return captured by the unix command calls.
  revid = [prefix str(1:end-1)];

  % Restore the current working directory to its previous state before exiting
  cd(oldcwd);
end

