function ax = axes2polaraxes(ax)
% ax = axes2polaraxes(ax)
%
% Creates a PolarAxes axis at the location of ax, deleting the original
% ax in the process.
%
% If ax is an array or cell array, each item in the list is converted.
%
% EXAMPLE
%   % Generate a grid of axes, but turn them into polar plots
%   axs = setup_axes(dim);
%   axs = axes2polaraxes(axs);
%

  if iscell(ax)
    ax = cellfunc(@axes2polaraxes, ax);
    return
  elseif length(ax) > 1
    ax = arrayfun(@axes2polaraxes, ax);
    return
  end

  p = get(ax, 'Position');
  u = get(ax, 'Units');
  fig = get(ax, 'Parent');
  delete(ax)
  ax = polaraxes(fig, 'Units', u, 'Position', p);
end
