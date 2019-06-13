function tf = isheadless()
% tf = isheadless()
%
% Determines whether Matlab is running in headless mode (no display connected)
% or not.
%

  if ispc() || ismac()
    error('Unhandled case')
  end

  % Cache the result, which cannot be changed while Matlab is running.
  persistent ptf;
  if ~isempty(ptf)
    tf = ptf;
    return
  end

  % If DISPLAY is empty, then X11 has not been setup/connected.
  DISPLAY = getenv('DISPLAY');
  tf = isempty(strtrim(DISPLAY));
  if tf
    ptf = tf;
    return
  end
  % but using the -nodisplay option actually keeps DISPLAY set, so we have
  % to keep checking.

  % Handle roots for post- and pre- R2014b graphics rewrite.
  try; gr = groot(); catch; gr = 0; end

  % On older Matlab versions, ScreenSize will have the width/height set to 1
  % if no display is available.
  sz = get(gr, 'ScreenSize');
  tf = isequal(sz(3:4), [1 1]);
  if tf
    ptf = tf;
    return
  end

  % If there's a figure available, see if it knows about the display system.
  fig = get(gr, 'CurrentFigure');
  if ~isempty(fig)
    tf = strcmp(get(fig, 'XDisplay'), 'nodisplay');
    if tf
      ptf = tf;
      return
    end
  end

  % We leave this test for last. According to StackOverflow [1], this is
  % not reliable if invoked during parallel executiong, but it's the best
  % we've got at this point.
  %   [1]: https://stackoverflow.com/a/30240946
  tf = ~usejava('display');
  if tf
    ptf = tf;
    return
  end

  tf = false;
  ptf = tf;
end
