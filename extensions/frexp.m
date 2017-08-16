function [s,e]=frexp(x)
% [s,e]=frexp(x)
%
% Alias for [s,e] = log2(x), matching the ANSI C name.
%

  [s,e] = log2(x);
end
