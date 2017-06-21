function R=foldl(F,V0,V)
% R=foldl(F,V0,V)
%
% Reduces over the array V using the binary function F with left-
% associativity, where V0 is the initial reduction value. If V0 is empty,
% then the last element in V taken as the value for V0.
%
% EXAMPLE
%   R0 = ((1 / 2) / 3) / 4
%   R1 = foldr(@rdivide, [], 1:4)
%   R0 == R1
%

  if isempty(V0)
    R = V(1);
    S = 2;
  else
    R = V0;
    S = 1;
  end

  for ii=S:numel(V)
    R = F(R, V(ii));
  end
end

