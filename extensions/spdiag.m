function A=spdiag(v, N)
% A = spdiag(v, N)
%
% Generates a sparse diagonal matrix with the elements of v along the diagonal.
% If v is a scalar, then generate an NxN constant diagonal matrix.

  if numel(v) ~= 1 && (~exist('N', 'var') || isempty(N))
    N = length(v);
  end
  A = sparse(1:N, 1:N, v);
end
