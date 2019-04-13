function A = spinv(A)
% A = spinv(A)
%
% Sparsity-preserving multiplicative inverse; only non-zero elements have
% the transformation x -> 1/x applied.
%

  A = spfun(@(x) 1./x, A);
end
