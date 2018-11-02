function A=unpacktril(v,n,m,d)
% A=unpacktril(v,n,m,d)
%
  if ~exist('d','var') || isempty(d)
    d = 0;
  end
  A = zeros(n, m, 'like', v);
  mask = tril(true(size(A)), d);
  A(mask) = v;
end
