function prefix=lcp(S)
% prefix=lcp(S)
%
% Returns the longest common prefix to all strings. If no common prefix is
% found, then the empty string is returned.
%
% INPUTS
%   S         String or cell array of strings.
%
% OUTPUT
%   prefix    The longest common prefix to all elements in S.
%
% EXAMPLE
%   strs{1} = 'user/path/raw_input_variation1.txt';
%   strs{2} = 'user/path/raw_input_type1.txt';
%   strs{3} = 'user/path/raw_input_metadata.txt';
%   prefix = lcp(strs);
%

  % Default case
  prefix = '';

  if ~iscell(S) && ischar(S)
    prefix = S;
    return
  end

  if ~all(cellfun(@ischar, S))
    error('All inputs must be strings');
  end

  if length(S) == 1
    prefix = S{1};
    return
  end

  maxsz = min(cellfun(@length, S));

  endidx = 0;
  for ii=1:maxsz
    s0 = S{1}(ii);
    if ~all(cellfun(@(s) s(ii) == s0, S(2:end)))
      break
    end
    endidx = ii;
  end

  if endidx > 0
    prefix = S{1}(1:endidx);
  end
end


