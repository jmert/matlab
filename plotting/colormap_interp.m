function cmap=colormap_interp(cmap,n,space)
% cmap=colormap_interp(cmap,n,space)
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

  if ~exist('space','var') || isempty(space)
    if exist('rgb2lab','file')
      space = 'lab';
    else
      space = 'gamma';
    end
  end
  switch space
    case {'linear','rgb'}
      trans = @id;
      invtrans = @invid;
    case 'gamma'
      trans = @gamma;
      invtrans = @invgamma;
    case 'lab'
      trans = @rgb2lab;
      invtrans = @lab2rgb;
    otherwise
      error('unknown interpolation space: %s', space);
  end

  cmap = trans(cmap);
  cmap = interp1(linspace(1, n, m), cmap, 1:n);
  cmap = invtrans(cmap);
  cmap(cmap < 0) = 0;
  cmap(cmap > 1) = 1;
end

function x=id(x)
end
function x=invid(x)
end

function x=gamma(x)
  x = x .^ 2.2;
end
function x=invgamma(x)
  x = x .^ (1/2.2);
end
