function st=sparsify(st)
% st=sparsify(st)
%
% Converts everything within the given structure to sparse arrays, including
% recursivley descending into child structures.
%
% INPUTS
%   st    A generic structure which can contain arrays, cell arrays, or
%         further nested structures.
%
% OUTPUTS
%   st    Equivalent to input structure except elements have been turned into
%         sparse arrays, including elements within nested structures.
%
% EXAMPLE
%
%   ac = sparsify(ac);
%

  fnames = fieldnames(st);

  % Recursively call this function for all elements of a structure array.
  if numel(st) > 1
    for ii=1:numel(st)
      st(ii) = sparsify(st(ii));
    end
    return
  end

  % We'll only get here for a "scalar" structure
  for f=1:length(fnames)
    ff=fnames{f};

    if isstruct(st.(ff))
      st.(ff) = sparsify(st.(ff));

    elseif iscell(st.(ff))
      for cc=1:length(st.(ff))
        if isfloat(st.(ff))
          st.(ff){cc} = sparse(st.(ff){cc});
        end
      end

    elseif isfloat(st.(ff))
      st.(ff) = sparse(st.(ff));
    end
  end

end
