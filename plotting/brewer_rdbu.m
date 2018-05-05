function varargout=brewer_rdbu(n)
% cmap=brewer_rdbu(n)
%
% Generates the Brewer2 RdBu color map for n points.
%

  if ~exist('n','var') || isempty(n)
    n = 128;
  end

  % Taken from http://colorbrewer2.org/#type=diverging&scheme=RdBu&n=11
  % and reversed in order so that "cold" is blue.
  cmap = [
      5    48    97;
     33   102   172;
     67   147   195;
    146   197   222;
    209   229   240;
    247   247   247;
    253   219   199;
    244   165   130;
    214    96    77;
    178    24    43;
    103     0    31] ./ 255;

	cmap = colormap_interp(cmap, n);
	if nargout == 0
		colormap(cmap);
  else
    varargout{1} = cmap;
  end
end

