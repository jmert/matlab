function [fpart,ipart]=modf(x)
% [fpart,ipart]=modf(x)
%
% Returns the fractional and integral parts of x. Aims to correspond to the
% ANSI C function modf().
%

  s = ones(size(x));
  t = x < 0;
  s(t) = -1;
  x(t) = -x(t);

  ipart = floor(x);
  fpart = s.*(x - ipart);
  ipart = s.*ipart;
end
