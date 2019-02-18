function setfigsize(fig, w, h)
% setfigsize(fig, w, h)
%
% Resizes the given figure to dimension w-by-h, where w and h are given in
% the figure's current units. (The paper units will be made to match while
% updating the paper size.)
%

  if ~exist('fig','var') || isempty(fig)
    fig = gcf();
  end

  % Update size while [trying to] keep the top-left position at the same
  % place. (Doesn't actually seem to work for me perfectly...)
  op = get(fig, 'OuterPosition');
  p = get(fig, 'Position');
  p(2) = p(2) + p(4) - h;
  p(3) = w;
  p(4) = h;
  set(fig, 'Position', p);

  % Save current paper units
  punits = get(fig, 'PaperUnits');
  set(fig, 'PaperUnits', get(fig, 'Units'));
  set(fig, 'PaperSize', [w h], ...
           'PaperPosition', [0 0 w h]);
  % Restore paper units
  set(fig, 'PaperUnits', punits);
end
