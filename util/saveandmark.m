function saveandmark(filename,varargin)
% saveandmark(filename,varargin)
%
% Wrapper around Matlab's save() function which injects the repository
% revision ID as well as verifies that the save has been performed without
% data corruption by reloading the revision ID from the saved file. Saving
% will be retried up to 3 times.
%
% INPUTS
%   filename    The file path to save.
%
%   varargin    save() options and arguments. See save() for more information
%               on available arguments and syntax.
%

  if ~ischar(filename)
    error('saveandmark:argumentType', '''filename'' must be a string');
  end

  if ~all(cellfun(@ischar, varargin))
    error('saveandmark:argumentType', ...
      'Arguments must be option strings or variable names');
  end

  % Now start parsing the given arguments. Find the options and variables so
  % that we can process them.
  isopt = strncmp('-', varargin, 1);
  options = lower(varargin(isopt));
  variables = varargin(~isopt);

  % Construct filenames
  [fpath,fname,fext] = fileparts(filename);
  if isempty(fext) && ~ismember('-ascii', options)
    fext = '.mat';
    filename = fullfile(fpath, [fname '.mat']);
  end

  % Also generate a temporary file name
  tmpfilename = fullfile(fpath, [fname '.' gen_stamp() 'tmp' fext]);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Uptake variables
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Storage of all variables that are to be saved to disk
  tosave = struct();
  % Initially populate with at least the repository revision
  tosave.revid = get_rev_id();

  % We need to handle the -struct option specifically
  if ismember('-struct', options)
    % For saving structs, only the first variable is a variable, and then the
    % rest of the list is taken to be the fieldnames to actually save.
    varname = variables{1};
    fields = variables(2:end);

    % Verify that the variable exists
    if isempty(evalin('caller', ['who(''' varname ''')']))
      error('saveandmark:undefinedVariable', ...
        ['Undefined variable ''' varname ''' in caller workspace.']);
    end

    % Alias the structure in the local workspace
    var = evalin('caller', varname);

    % Verify that the variable is actually a structure
    if ~isstruct(var);
      error('saveandmark:structType', ...
        ['''' varname ''' is not a structure.']);
    end

    % Get the list of fields to alias if none were specified
    if isempty(fields)
      fields = fieldnames(var);
    end

    % Now alias the members into the save structure
    for ii=1:length(fields)
      tosave.(fields{ii}) = var.(fields{ii});
    end
    clear var

  % Otherwise, just alias in variables from the caller workspace.
  else
    for ii=1:length(variables)
      % Verify that the variable exists
      if isempty(evalin('caller', ['who(''' variables{ii} ''')']))
        error('saveandmark:undefinedVariable', ...
          ['Undefined variable ''' variables{ii} ''' in caller workspace.']);
      end

      % Now alias into the save structure
      tosave.(variables{ii}) = evalin('caller', variables{ii});
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save, test, and retry
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  maxNsaves = 2;
  Nsaves = 0;
  saveOK = false;

  options = union('-struct', options);

  % Try to save the file a few times
  while Nsaves < maxNsaves
    save(tmpfilename, options{:}, 'tosave');

    % Verify the file by loading a known variable
    try
      vrevid = load(tmpfilename, 'revid');
      saveOK = true;
      break

    % load() throws an error if the file is corrupted, so capture and
    % initiate a retry.
    catch
      fprintf(1, 'File ''%s'' did not save properly. Retrying...\n', ...
        filename);
      Nsaves = Nsaves + 1;
    end
  end

  % Clean up after ourselves if all the attempts failed and throw an error
  if ~saveOK
    system_safe(sprintf('rm -f ''%s''', tmpfilename));
    error('saveandmark:saveFailed', ...
      ['Failed to save ''' filename '''.']);
  end

  % If we got here, everything went OK, so move from temporary
  system_safe(sprintf('mv ''%s'' ''%s''', tmpfilename, filename));
end
