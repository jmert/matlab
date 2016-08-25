function combos=combinations(varargin)
% combos=combinations(varargin)
%
% Returns a cell-of-cells vector where each element cell array is a unique
% combination of one element from each of the input arguments.
%
% EXAMPLE
%
%   colors = {'black','red','green','blue'};
%   tf = [true, false];
%   optcombos = combinations(colors, tf, tf, tf);
%   for ii=1:length(optcombos)
%     [color,bold,underline,italic] = deal(optcombos{ii}{:});
%     fancyhtml(color, bold, underline, italic);
%   end
%

  % The number of input arguments determines the number of dimensions in the
  % output, and the size of each dimension corresponds to the number of
  % values given in each argument.
  ndims = numel(varargin);

  for ii=1:ndims
    if iscell(varargin{ii})
      varargin{ii} = cellfunc(@(v) {v}, varargin{ii});
    else
      varargin{ii} = arrayfunc(@(v) {v}, varargin{ii});
    end
    varargin{ii} = reshape(varargin{ii}, 1, []);
  end

  combos = varargin{1}';

  for ii=2:ndims
    combos = repmat(combos, 1, numel(varargin{ii}));
    nextc  = repmat(varargin{ii}, size(combos,1), 1);
    combos = cellfunc(@horzcat, combos, nextc);
    combos = reshape(combos, [], 1);
  end
end

