function colorbar_axis(cbar,clim,varargin)
% colorbar_axis(cbar, clim, varargin)
%
% Transfroms the axis cbar into a colorbar-like axis by rendering a gradient
% and setting auxiliary properties (such as right-side labels, smaller font,
% etc).
%
% INPUTS
%   cbar     An axis handle to be used as the colorbar.
%
%   clim     Color axis limits to be used.
%
% EXAMPLE
%
%   dim = get_default_dim();
%
%   dim.W = 6.5;
%   wd = dim.W - 2*dim.wide - 2*dim.med - dim.cbar - dim.thin;
%   dim.x{1,1} = dim.wide+dim.med + [0, wd];
%   dim.y{1,1} = dim.wide+dim.med + [0, wd];
%   dim.x{1,2} = dim.x{1,1}(2) + dim.thin + [0, dim.cbar];
%   dim.y{1,2} = dim.y{1,1};
%   dim.H = dim.y{1,1}(2) + dim.wide;
%
%   [fig,axs] = dpifigure(dim);
%   nanimagesc(axs{1,1}, -25:25, -25:25, randn(51,51));
%   colorbar_axis(axs{1,2}, exp(1/2) * [-1,1]);
%   colormap gray
%

  p = inputParser();
  p.FunctionName = 'colorbar_axis';
  addOptional(p, 'FontSize', 0.75 * get(cbar, 'FontSize'));
  addOptional(p, 'Title', []);
  parse(p, varargin{:});
  opts = p.Results;

  cdata = repmat(linspace(clim(1), clim(2), 256)', 1, 2);
  imagesc(cbar, 1:2, cdata(:,1), cdata);
  set(cbar, 'YDir', 'normal');
  set(cbar, 'XTick', [], 'XTickLabel', []);
  set(cbar, 'YAxisLocation', 'right');

  set(cbar, 'FontSize', opts.FontSize);
  if ~isempty(opts.Title)
    set(get(cbar,'YLabel'), 'String', opts.Title);
  end
end


