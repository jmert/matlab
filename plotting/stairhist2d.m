function [hax,hline]=stairhist2d(x,y,A)
% [hax,hline]=stairhist2d(x,y,A)
%
% Plots a 2D histogram + 2×1D projections in a single plot.
%
% INPUTS
%   x,y   Histogram bin centers for the matrix A in each of the dimensions.
%         It is assumed that x,y are uniformly spaced.
%
%   A     Matrix of histogram vlaues.
%
% OUTPUTS
%   hax     Vector of axis handles, ordered as the main 2D histogram, then the
%           top axis (projection through all y of the x distribution), and
%           finally the right-side axis (projection through all x of the y
%           distribution).
%
%   hline   Vector of handles to the plots, being a image for the main 2D
%           histogram and stair-step lines for the projections.
%
% EXAMPLE
%
%   [x_tic, y_tic, A] = histogramming_function();
%   stairhist2d(x_tic, y_tic, A);
%

  frac = 6;

  m = frac;
  n = m + 1;
  pls = reshape(1:n^2, n, n)';

  x = x(:);
  y = y(:);
  xe = [x(1:end-1)-diff(x)/2; (3*x(end)-x(end-1))/2];
  ye = [y(1:end-1)-diff(y)/2; (3*y(end)-y(end-1))/2];
  xp = sum(A, 1);
  yp = sum(A, 2);

  main = subplot(n, n, rvec(pls(2:n,1:m)));
  hmain = imagesc(x, y, A);
  axis xy

  top = subplot(n, n, rvec(pls(1,1:m)));
  htop = stairs(xe, xp);
  set(gca(), 'XTickLabel', {});

  side = subplot(n, n, rvec(pls(2:n,n)));
  hside = stairs(ye, yp);
  view([90, -90])
  set(gca(), 'XTickLabel', {});

  hax = [main; top; side];
  hline = [hmain; htop; hside];
end
