function colorbar_axis(cbar, clim, varargin)
% colorbar_axis(cbar, clim, varargin)
%
% Transfroms the axis cbar into a colorbar-like axis by rendering a gradient
% and setting auxiliary properties (such as right-side labels, smaller font,
% etc). Motivated by the fact that Matlab's built-in colorbars must be attached
% to an axis object, but by doing so, the axis is resized to accomodate the
% colorbar; therefore, getting absolute positioning of builtin colorbars
% is difficult.
%
% INPUTS
%   cbar      An axis handle to be used as the colorbar.
%
%   clim      Color axis limits to be used.
%
%   varargin  Key-value option pairs. See OPTIONAL ARGUMENTS below.
%
% OPTIONAL ARGUMENTS
%
%   FontSize
%     Defaults to 75% of the default axis font size. Sets the size of fonts
%     used on the vertical axis.
%
%   Scale
%     Defaults to 'linear'. To use a logarithmic color scale, set to 'log',
%     in which case clim should be the logarithmic endpoint values; i.e.
%     clim = [-3 0] to have a logarithmic scale from 1e-3 to 1.
%
%   Title
%     Defaults to []. If not empty, the y-axis label for the colorbar axis
%     is set the given title string.

  props = get(cbar, 'UserData');
  if ~isstruct(props)
    props = struct();
  end
  if isfieldset(props, 'FontSize')
    deffont = props.FontSize;
  else
    deffont = 0.75 * get(groot(), 'defaultAxesFontSize');
  end

  p = inputParser();
  p.KeepUnmatched = true;
  p.FunctionName = 'colorbar_axis';
  addOptional(p, 'FontSize', deffont);
  addOptional(p, 'Interpreter', 'tex');
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
    set(get(cbar,'YLabel'), ...
        'Interpreter', opts.Interpreter, ...
        'String', opts.Title);
  end
  props.Colorbar = true;
  props.FontSize = opts.FontSize;
  set(cbar, 'UserData', props);
end


