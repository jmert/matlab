function colorlines(lines, cmap)
% colorlines(lines, cmap)
%
% Updates the colors of the provided lines with successive entries from the
% provided colormap.
%

  nmap = size(cmap, 1);
  for ii = 1:length(lines)
    set(lines(ii), 'Color', cmap(mod(ii-1, nmap) + 1, :));
  end
end
