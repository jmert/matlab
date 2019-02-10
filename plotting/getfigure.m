function h=getfigure(name)
  h = findobj(groot(), 'Type', 'Figure', 'Name', name);
  if isempty(h)
    h = figure();
    set(h, 'Name', name);
  end
end

