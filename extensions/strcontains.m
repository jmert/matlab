function tf=strcontains(str,pattern)
% tf=strcontains(str,pattern)
%
% Returns true if pattern is found in str anywhere, otherwise false.
%
% Just a simple utility wrapper, equivalent to
%   tf = ~isempty(strfind(str, pattern));
%

  tf = ~isempty(strfind(str, pattern));
end

