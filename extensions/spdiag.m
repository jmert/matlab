function D=spdiag(v)
  D = sparse(1:length(v), 1:length(v), v);
end
