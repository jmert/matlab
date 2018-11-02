function v=packtril(A,d)
% v=packtril(A,d)
%
% Generates a vector which packs the column-major list of unique elements from
% the lower triangle of A, with respect to the d-th diagonal. d defaults to 0.

  if ~exist('d', 'var') || isempty(d)
    d = 0;
  end
  mask = tril(true(size(A)), d);
  v = A(mask(:));
end
