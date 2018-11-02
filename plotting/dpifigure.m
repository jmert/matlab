function varargout=dpifigure(varargin)
% [fig,ax]=dpifigure(dim,varargin)
% fig=dpifigure(w,h,varargin)
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
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
% KEY-VALUE OPTIONS
%
%   'Controls'
%
%   'FontSize'
%
%   'Resize'

  % Parse the remaining arguments
  p = inputParser();
  p.FunctionName = 'dpifigure';

  isbool = @(x) (isnumeric(x) || islogical(x)) && isscalar(x);
  issize = @(x) isnumeric(x) && isscalar(x) && isreal(x) && x > 0;

  % Handle the two forms of input differently.
  if isstruct(varargin{1})
    mkaxes = true;
    pos = varargin(1);
    addRequired(p, 'dim', @isstruct);
    varargin = varargin(2:end);
  else
    mkaxes = false;
    pos = varargin(1:2);
    addRequired(p, 'FigW', issize);
    addRequired(p, 'FigH', issize);
    varargin = varargin(3:end);
  end

  % Optional modifications to make to the plot
  addOptional(p, 'Controls', false, isbool);
  addOptional(p, 'FontSize', 10,    issize);
  addOptional(p, 'Resize',   true,  isbool);

  parse(p, pos{:}, varargin{:})
  opts = p.Results;

  controls = {};
  if ~opts.Controls
    controls = {'MenuBar','none', 'ToolBar','none', 'DockControls','off'};
  end
  fig = figure(controls{:});

  % Tick marks seem to actually show up consistently for painters, whereas
  % they do sporadic things when using default opengl renderer.
  % Also compatible with saving vectorized EPS/PDF figures.
  set(fig, 'Renderer', 'painters');

  % Work in physical paper units
  set(fig, 'Units', 'inches');
  set(fig, 'PaperUnits', 'inches');
  % Matlab in R2015b+ apparently is "DPI aware", but that equates to the
  % rendered fonts' sizes depending on your system DPI. This is terrible for
  % reproducible plots across systems, so instead we'll try adopting TeX's
  % definition of a point where 1 in == 72.27 pt. Specify a default font
  % size interpreted as TeX points (i.e. scale by ratio betwen TeX and current
  % screen pixels per inch).
  ppi = get(groot(), 'ScreenPixelsPerInch');
  ratio = 72.27 / ppi;
  set(fig, ...
      'defaultAxesFontSize', opts.FontSize * ratio, ...
      'defaultTextFontSize', 1.15*opts.FontSize * ratio);

  % Default figure color is white.
  set(fig, 'Color', [1 1 1]);

  if ~verLessThan('matlab','8.4')
    set(fig, 'defaultAxesTitleFontWeight', 'normal');
  end
  % Turn on the axis boxes by default
  set(fig, 'defaultAxesBox', 'on');
  % No need for a white background when the figure is already white. This
  % seems to simplify the PDF just a bit (confirmed by opening PDF in
  % Inkscape and comparing grouped contents --- the none case has one
  % fewer white rectangle).
  set(fig, 'defaultAxesColor', 'none');
  % Use thin lines
  set(fig, 'defaultLineLineWidth', 0.5);

  varargout{1} = fig;
  % Do this last to be compatible with the setup_axes() case, which needs to
  % have all of the other setup done for the new axes to inherit the relevant
  % settings.
  if mkaxes
    varargout{2} = setup_axes(opts.dim);
  else
    % Set physical and on-screen dimensions to match
    drawnow();
    p = get(fig, 'Position');
    set(fig, 'PaperSize',         [opts.FigW opts.FigH], ...
             'PaperPosition', [0 0 opts.FigW opts.FigH]);
    drawnow();
    set(fig, 'Position', [p(1) p(2) opts.FigW opts.FigH]);
  end
  if ~opts.Resize
    set(fig, 'Resize', 'off');
  end
end

