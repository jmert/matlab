function A=flatten(A)
% function A=flatten(A)
%
% Flattens a cell array such that all members are non-cell arrays.
%

  if ~iscell(A)
    return
  end

  cells = cellfun(@iscell, A);
  while any(cells)
    idx = find(cells, 1, 'first');
    A = [A(1:(idx-1)), A{idx}, A((idx+1):end)];

    cells = cellfun(@iscell, A);
  end
end

