function path=datapath()
% path=datapath()
%
% Constructs a data file path prefix for each project script, built from
% matching the script name for the SNNNN_ prefix naming scheme.
%
%

  st = dbstack('-completenames');
  if length(st) < 2
    error('datapath() cannot be used interactively')
  end

  for ii=2:length(st)
    callername = st(ii).name;
    project = regexpi(callername, '^(S\d{4})(?=_)', 'match');
    if length(project) == 1 && ~isempty(project{1})
      path = fullfile('temp', project{1});
      return
    end
  end

  error('could not automatically construct data path')
end
