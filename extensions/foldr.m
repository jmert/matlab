function R=foldr(F,V0,V)
% R=foldr(F,V0,V)
%
% Reduces over the array V using the binary function F with right-
% associativity, where V0 is the initial reduction value. If V0 is empty,
% then the last element in V taken as the value for V0.
%
% EXAMPLE
%   R0 = 1 / (2 / (3 / 4))
%   R1 = foldr(@rdivide, [], 1:4)
%   R0 == R1
%

  if isempty(V0)
    R = V(end);
    N = numel(V) - 1;
  else
    R = V0;
    N = numel(V);
  end

  for ii=N:-1:1
    R = F(V(ii), R);
  end
end

