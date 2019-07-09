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
  p.KeepUnmatched = true;
  p.FunctionName = 'colorbar_axis';
  addOptional(p, 'FontSize', 0.75 * get(groot(), 'defaultAxesFontSize'));
  addOptional(p, 'Scale', 'linear');
  addOptional(p, 'Title', []);
  parse(p, varargin{:});
  opts = p.Results;

  switch lower(deblank(opts.Scale))
    case 'linear'
      yvals = linspace(clim(1), clim(2), 256);
      cdata = yvals;
      cdata = repmat(cdata', 1, 2);
      imagesc(cbar, 1:2, yvals, cdata);
      set(cbar, 'YDir', 'normal');
    case 'log'
      yvals = logspace(clim(1), clim(2), 256);
      cdata = log10(yvals);
      cdata = repmat(cdata', 1, 2);
      surf = pcolor(cbar, 1:2, yvals, cdata);
      set(surf, 'EdgeColor', 'none', 'LineStyle', 'none');
      set(cbar, 'YScale', opts.Scale);
  end
  set(cbar, 'XTick', [], 'XTickLabel', []);
  set(cbar, 'YAxisLocation', 'right');

  set(cbar, 'FontSize', opts.FontSize);
  if ~isempty(opts.Title)
    set(get(cbar,'YLabel'), 'String', opts.Title);
  end
  props = get(cbar, 'UserData');
  if ~isstruct(props)
    props = struct();
  end
  props.Colorbar = true;
  set(cbar, 'UserData', props);
end


