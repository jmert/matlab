function R=foldrc(F,V0,V)
% R=foldrc(F,V0,V)
%
% Reduces over the cell array V using the binary function F with right-
% associativity, where V0 is the initial reduction value. If V0 is empty,
% then the last element in V taken as the value for V0.
%
% EXAMPLE
%   [X{:}] = deal(rand(4), rand(4), rand(4));
%   R0 = X{1} - (X{2} - X{3})
%   R1 = foldrc(@minus, [], X)
%   all(R0(:) == R1(:))
%

  if isempty(V0)
    R = V{end};
    N = numel(V) - 1;
  else
    R = V0;
    N = numel(V);
  end

  for ii=N:-1:1
    R = F(V{ii}, R);
  end
end

