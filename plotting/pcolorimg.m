function im = pcolorimg(varargin)
% im = pcolorimg(A)
% im = pcolorimg(x, y, A)
%
% Similar to imagesc(A) but plots using pcolor, taking care to add the necessary
% extra row/column of padding to the end and setting the patch edge colors
% to invisible.

  if nargin == 3
    x = varargin{1};
    y = varargin{2};
    A = varargin{3};
  else
    A = varargin{1};
    x = (1:size(A,2))';
    y = (1:size(A,1))';
  end

  x = x(:);
  y = y(:);
  if numel(x) == size(A,2) && numel(y) == size(A,1)
    sx = diff(x); sx(end+1) = sx(end);
    sy = diff(y); sy(end+1) = sy(end);
    x = [x - sx/2; x(end) + sx(end)/2];
    y = [y - sy/2; y(end) + sy(end)/2];

  % Allow for the exact pixel boundaries to be given by the user, so only
  % error if not 1 longer than the array.
  elseif numel(x) ~= size(A,2)+1 || numel(y) == size(A,1)+1
    error('Invalid x or y given dimensions of A');
  end
  A = padarray(A, [1 1], NaN, 'post');

  [xx,yy] = meshgrid(x, y);
  im = pcolor(xx, yy, A);
  set(im, 'EdgeColor', 'none');
  % Replicate behavior of imagesc()
  set(gca(), 'YDir', 'reverse');
end
