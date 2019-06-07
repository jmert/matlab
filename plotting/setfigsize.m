function fig=figsize(fig, w, h)
% fig=setfigsize(fig, w, h)
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
  p = get(fig, 'Position');
  p(2) = max(0, p(2) + p(4) - h);
  p(3) = w;
  p(4) = h;
  set(fig, 'Position', p);
  % Matlab apparently can't figure out how to correctly size a figure when it
  % hasn't yet actually made it to your screen. So register a callback
  % function to instead schedule an update the next time the figure
  % "resizes" which includes having it actually show to the screen.
  try
    set(fig, 'SizeChangedFcn', @(varargin) fuckyoumatlab(w, h, varargin{:}));
  catch
    set(fig, 'ResizeFcn', @(varargin) fuckyoumatlab(w, h, varargin{:}));
  end

  % Save current paper units
  punits = get(fig, 'PaperUnits');
  set(fig, 'PaperUnits', get(fig, 'Units'));
  set(fig, 'PaperSize', [w h], ...
           'PaperPosition', [0 0 w h]);
  % Restore paper units
  set(fig, 'PaperUnits', punits);
end

function fuckyoumatlab(w, h, self, varargin)
  drawnow()
  pos = get(self, 'Position');
  wh  = pos(3:4);
  if ~isequal(wh, [w h])
    pos(1:2) = max([0 0], pos(1:2));
    pos(3:4) = [w h];
    set(self, 'Position', pos)
  else
    try
      set(self, 'SizeChangedFcn', []);
    catch
      set(self, 'ResizeFcn', []);
    end
  end
end
