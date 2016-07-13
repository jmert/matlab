function ax=setup_axes(dim)
% ax=setup_axes(dim)
%
% Sets up a figure with a particular size (in inches) and arranges a series
% of axes within the figure according to a set of grid dimensions.
%
% INPUTS
%
%   dim    Structure defining the dimensions and layout of the plots to create.
%          Required members:
%
%            .W    Width of the total figure, in inches.
%
%            .H    Height of total figure, in inches.
%
%            .x    Cell-array grid of 1x2 numeric arrays that give the left
%                  and right edges of the axes. Given in inches.
%
%            .y    Cell-array grid of 1x2 numeric arrays that give the top
%                  and bottom edges of the axes. Given in inches.
%
%                  .x and .y must have same dimensions.
%
%                  Spanning rows or columns may be created by setting any one
%                  member of the row or column to the full desired size, and
%                  then the spanned cells should have empty dimensions to
%                  suppress having an axis drawn in that position.
%
% OUTPUTS
%
%   ax     A cell matrix of axes handles that correspond to each of the grid
%          positions enumerated in the dim struct.
%
% EXAMPLE
%
%   dim.W = 6.5;     % 6.5" wide figure. Height will be calculated to fit.
%   dim.wide = 0.30; % Wide spacing
%   dim.med  = 0.15; % Medium spacing
%   dim.thin = 0.05; % Thin spacing
%   dim.cbar = 0.15; % Width of manually drawn color bars
%
%   % Plot two BICEP maps side-by-side with a shared "colorbar" on the right.
%   % (The colorbar will be manually drawn with imagesc().)
%
%   m = get_map_defn('bicep');
%   mapw = (dim.W - dim.wide - 3*dim.thin - dim.cbar) / 2;
%   maph = mapw * m.ydos/m.xdos;
%
%   dim.x{1,1} =                 dim.wide + [0, mapw];
%   dim.x{1,2} = dim.x{1,1}(2) + dim.thin + [0, mapw];
%   dim.x{1,3} = dim.x{1,2}(2) + dim.thin + [0, dim.cbar];
%   dim.y{1,1} =                 dim.wide + [0, maph];
%   dim.y{1,2} = dim.y{1,1};
%   dim.y{1,3} = dim.y{1,1};
%
%   dim.H = dim.y{1,1}(2) + dim.wide;
%
%   ax = setup_axes(dim);
%

  % Make sure we can actually construct a proper grid.
  if ~all(size(dim.x) == size(dim.y))
    error('X and Y grids have incompatible sizes.')
  end
  ht = size(dim.x, 1);
  wd = size(dim.x, 2);

  % Translate all grid coordinates into relative page coordinates.
  dim.x = cellfun(@(c) c ./ dim.W, dim.x, 'uniformoutput', false);
  dim.y = cellfun(@(c) c ./ dim.H, dim.y, 'uniformoutput', false);

  % Arrange the figure/paper correctly.
  clf();
  set(gcf, 'Units','inches');
  p = get(gcf, 'Position');
  set(gcf, 'Position', [p(1), p(2)+p(4)-dim.H, dim.W, dim.H])
  set(gcf, 'PaperUnits', 'inches', 'PaperPosition', [0 0 dim.W dim.H]);
  set(gcf, 'PaperSize', [dim.W dim.H]);
  clear p;

  ax = cell(ht,wd);

  % Now start filling axes
  for ii=1:wd
    for jj=1:ht
      x = dim.x{jj,ii};
      y = dim.y{jj,ii};

      % If this cell is being spanned (or just should be left empty) as
      % indicated by an empty set of dimensions, skip creating an axis in this
      % position.
      if isempty(x) || isempty(y)
        continue
      end

      ax{jj,ii} = axes('Position', [x(1), y(1), diff(x), diff(y)]);
    end
  end
end