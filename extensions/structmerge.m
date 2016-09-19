function C=structmerge(A,B)
% C=structmerge(A,B)
%
% Merges the contents of B into A, overwriting any common fields between A and
% B with the values in B, returning the combined result in C.
%

  % Allow A or B to be empty and act as a no-op, passing through the other
  % value.
  if isempty(A)
    C = B;
    return
  elseif isempty(B)
    C = A;
    return
  end

  % Get a copy of A with fields specified in B removed.
  C = rmfield(A, intersect(fieldnames(A), fieldnames(B)));
  % Then copy in the values from B to C.
  for ff=rvec(fieldnames(B))
    C.(ff{:}) = B.(ff{:});
  end
end

function v=rvec(v)
  v = v(:)';
end

