function path=mkdir_p(path)
% path=mkdir_p(path)
%
% Emulates the POSIX `mkdir -p` behavior, creating all parent components of
% the path if necessary.
%

  if exist(path, 'dir')
    return
  end
  comps = {};
  while true
    [path,part] = fileparts(path);
    comps{end+1} = part;
    if isempty(path) || isrootpath(path)
      break
    end
  end
  comps = comps(end:-1:1);
  for ii = 1:length(comps)
    path = fullfile(path, comps{ii});
    if ~exist(path, 'dir')
      mkdir(path)
    end
  end
end

function tf=isrootpath(path)
  if isunix()
    tf = strcmp(path, '/');
  else
    tf = strcmp(path(2:end), ':\');
  end
end
