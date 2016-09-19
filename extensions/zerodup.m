function B=zerodup(A)
% function B=zerodup(A)
%
% Create a duplicate of A which has zeroed all elements. An intended use case
% is to give an "empty" copy which can be replicated with repmat().
%

  B = [];

  % Descend into structs and work on the fields
  if isstruct(A)
    fnames = fieldnames(A(1));
    for ii=1:length(fnames)
      % Do all the work of handling fields in a struct by just recursively
      % calling ourself.
      B.(fnames{ii}) = zerodup(A(1).(fnames{ii}));
    end

  % Cell arrays need to be handled element-by-element since types internally
  % can differ.
  elseif iscell(A)
    for ii=1:length(A)
      % Again, just call ourself recursively and let the top-level cases
      % handle the contents
      B{ii} = zerodup(A{ii});
    end

  % Sparse arrays are more special than a dense array, so capture that case
  % first.
  elseif issparse(A)
    ss = size(A);
    B = sparse(ss(1), ss(2));

  % Zeros don't make sense for character strings, so handle it specially
  elseif ischar(A)
    B = '';

  % Final handled case is just a regular, numeric array.
  elseif isnumeric(A)
    B = zeros(size(A), class(A));

  % Other things should emit a warning about unrecognized data types. Default
  % to just giving back an empty array in this case.
  else
    B = [];
    warning('zerodup:DataTypeError', sprintf(...
      'Encountered unhandled data type `%s`; setting to empty list.', ...
      class(A)))
  end

end
