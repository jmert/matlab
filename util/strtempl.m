function str=strtempl(template)
% str=strtempl(template)
%
% Performs template substitution of variable values into the provided string
% by searching for corresponding variables in the caller's local scope.
%
% INPUTS
%   template    A string containing replacement templates identified by a
%               pair of double curly braces. The template takes the form:
%
%                   {{varname%sprintf}}
%
%               where `varname` is a variable name in the caller scope and
%               `sprintf` is the corresponding string formatting used by
%               sprintf(). The `%sprintf` portion is optional, in which case
%               the following defaults will be used based on the variable
%               class:
%
%                   '%d'      double, single
%                   '%s'      char
%                   '%i'      uintXX, intXX where XX = {8,16,32,64}
%
% OUTPUTS
%
%   str         The formatted string.
%
% EXAMPLES
%
%   sernum = 1351;
%   rlz = 1;
%   daughter = 'd';
%   type = 3;
%   jack = '0';
%
%   mapname = strtempl(['maps/{{sernum%04i}}/{{rlz%03i}}{{type%1i}}_' ...
%             '{{daughter}}_filtp3_weight3_gs_dp1100_jack{{jack}}.mat']);
%
  % Identify the position of all the start markers
  sidx = strfind(template, '{{');
  % If no markers are identified, just return the template now.
  if isempty(sidx)
    str = template;
    return;
  end
  eidx = strfind(template, '}}');

  % Make sure there are as many opening as closing pairs of braces.
  if numel(sidx) ~= numel(eidx)
    throwAsCaller(MException('strtempl:malformedTemplate', ...
      'Malformed template string. Unmatched opening and closing braces.'));
  end
  % Also make sure the braces are not interlaced.
  if ~all(sidx < eidx) || ~all(sidx(2:end) > eidx(1:end-1))
    throwAsCaller(MException('strtempl:malformedTemplate', ...
      'Malformed template string. Braces are interleaved.'));
  end

  % The length of sidx tells us how many substitutions need to be made. Use
  % that information to create a cell array which will store the rest of the
  % information we'll need.
  %
  %    column 1: 1-by-2 array with start and end indices in template of the
  %              substitution
  %    column 2: the variable name
  %    column 3: the sprintf() argument
  %    column 4: the data pulled from the caller context.

  % Initialize with contents before the first replacement.
  sprintfstr = template(1:sidx(1)-1);

  vars = cell(numel(sidx), 4);
  for ii=1:numel(sidx);
    % Store the marker indices. Add 1 to the end to indicate the end of the
    % two braces so that the bounds are inclusive.
    vars{ii,1} = [sidx(ii) eidx(ii)+1];
    % For convenience:
    ss = sidx(ii);
    ee = eidx(ii)+1;

    % Grab the replacement expression and try to tokenize it using '%'.
    [vars{ii,2},vars{ii,3}] = strtok(template(ss+2:ee-2), '%');

    % Now that we have the variable name, retreive it from the caller context.
    try
      vars{ii,4} = evalin('caller', vars{ii,2});
    catch ex
      % If we get an undefined error, report this as an incorrect usage of
      % this function.
      if strcmp(ex.identifier, 'MATLAB:UndefinedFunction')
        throwAsCaller(MException('strtempl:undefined', ...
          'The variable ''%s'' is undefined.', vars{ii,2}));

      % For any other type of error, just rethrow.
      else
        rethrow(ex);
      end
    end

    % Now make sure the sprintf string is not empty. If it is, we'll use the
    % variable type to guess one.
    if isempty(vars{ii,3})
      switch class(vars{ii,4})
        case {'single','double'}
          vars{ii,3} = '%d';
        case {'int8','uint8', 'int16','uint16', 'int32','uint32', ...
              'int64','uint64'}
          vars{ii,3} = '%i';
        case 'char'
          vars{ii,3} = '%s';
        otherwise
          throwAsCaller(MException('strtempl:typeError', ...
            'Implicit formatting for ''%s'' of type ''%s'' not possible.', ...
            vars{ii,2}, class(vars{ii,4})));
      end
    end

    % Now incrementally build the sprintf string.
    sprintfstr = [sprintfstr vars{ii,3}];
    if ii ~= numel(sidx)
      nextpart = template(ee+1:sidx(ii+1)-1);
    else
      nextpart = template(ee+1:end);
    end
    % To permit passing the output of this function to another printf-style
    % function, escape any '%%'.
    nextpart = strrep(nextpart, '%%', '%%%%');
    % Then append the string
    sprintfstr = [sprintfstr nextpart];
  end

  % With all the pieces assembled, simply produce the string.
  str = sprintf(sprintfstr, vars{:,4});
end

