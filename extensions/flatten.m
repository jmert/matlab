function A=flatten(A,squash)
% function A=flatten(A,squash)
%
% Flattens a cell array such that all members are non-cell arrays.
%
% INPUTS
%   A         The cell array to flatten.
%
%   squash    Optional, defaults to true. If false, then empty array
%             entries are not removed from the output.
%

  if ~exist('squash','var') || isempty(squash)
    squash = true;
  end

  if ~iscell(A)
    return
  end

  cells = cellfun(@iscell, A);
  while any(cells)
    idx = find(cells, 1, 'first');
    A = [A(1:(idx-1)), A{idx}, A((idx+1):end)];

    cells = cellfun(@iscell, A);
  end

  if squash
    A = A(~cellfun(@isempty, A));
  end
end

