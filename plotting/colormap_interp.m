function cmap=colormap_interp(cmap,n)
% cmap=colormap_interp(cmap,n)
%
% Interpolates the colormap from its given number of entries to n entries.
% Interpolation is done in the L*a*b colorspace (except when rgb2lab() fails
% due to i.e. not existing on old versions of Matlab, in which case the
% interpolation happens in RGB space instead.)
%

  m = size(cmap,1);
  if m == n
    return
  end

  labinterp = true;
  try
    cmap = rgb2lab(cmap);
  catch
    labinterp = false;
  end
  cmap = interp1(linspace(1, n, m), cmap, 1:n);
  if labinterp
    cmap = lab2rgb(cmap);
    % clamp within range
    cmap(cmap < 0) = 0;
    cmap(cmap > 1) = 1;
  end
end
