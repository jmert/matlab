function R=foldlc(F,V0,V)
% R=foldlc(F,V0,V)
%
% Reduces over the cell array V using the binary function F with left-
% associativity, where V0 is the initial reduction value. If V0 is empty,
% then the last element in V taken as the value for V0.
%
% EXAMPLE
%   [X{:}] = deal(rand(4), rand(4), rand(4));
%   R0 = (X{1} - X{2}) - X{3}
%   R1 = foldlc(@minus, [], X)
%   all(R0(:) == R1(:))
%

  if isempty(V0)
    R = V{1};
    S = 2;
  else
    R = V0;
    S = 1;
  end

  for ii=S:numel(V)
    R = F(R, V{ii});
  end
end

