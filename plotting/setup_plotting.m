function prepare_plotting()
  ud = get(groot(), 'UserData');
  if isempty(ud) || (ischar(ud) && ~strcmp(ud, 'setup_plotting'))
    % Clear all custom parameters before manipulating.
    close all
  end

  reset(groot());
  % Set white figure background, no axis background
  colordef(groot(), 'white');
  setmanual('defaultFigureColor', 'white', ...
            'defaultAxesColor', 'none');

  % Default to using measurements in inches.
  setmanual('defaultFigureUnits', 'inches', ...
            'defaultFigurePaperUnits', 'inches');

  % Make sure font sizes are fixed at known sizes
  setmanual('defaultAxesFontSize', 10, ...
            'defaultTextFontSize', 10, ...
            'defaultLegendFontSize', 8, ...
            'defaultColorbarFontSize', 8, ...
            'defaultLineMarkerSize', (6/10) * 8);

  set(groot(), 'defaultAxesTitleFontWeight', 'normal', ...
               'defaultAxesBox', 'on', ...
               'defaultFigureColormap', jet(256));

  % Set default size and have paper size match
  set(groot(), 'defaultFigurePosition', 'factory', ...
               'Units', 'inches');
  p = get(groot(), 'defaultFigurePosition');

  % 4:3 aspect ratio, 6.5 inches to match 8.5in - 2×1in margins
  wh = [6.5 4.875];
  set(groot(), 'defaultFigurePosition', [p(1:2) wh], ...
               'defaultFigurePaperSize', wh, ...
               'defaultFigurePaperPositionMode', 'manual', ...
               'defaultFigurePaperPosition', [0 0 wh]);

  % Use renderer compatible with saving vectorized PDFs by default.
  setmanual('defaultFigureRenderer', 'painters');

  set(groot(), 'UserData', 'setup_plotting');
end

function setmanual(varargin)
  for ii=1:2:length(varargin)
    mode  = varargin{ii};
    value = varargin{ii+1};
    set(groot(), mode, value, [mode 'Mode'], 'manual');
  end
end
