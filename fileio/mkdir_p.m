function path=mkdir_p(path)
% path=mkdir_p(path)
%
% Emulates the POSIX `mkdir -p` behavior, creating all parent components of
% the path if necessary.
%

  comps = {};
  while true
    [path,part] = fileparts(path);
    comps{end+1} = part;
    if isempty(path)
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
