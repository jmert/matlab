function highlight_regions(tag)

  fname = get_data_path(tag, 'tod');
  data = load(fname);
  [p,ind] = get_array_info(tag);

  % Chose a good pixel
  good_pixel = ind.rgl150(50);

  % Plot once to get the plot range of the data
  plot(data.d.mce0.data.fb(:,good_pixel));

  % Then retrieve the viewport parameters
  sz = axis;
  xmin = sz(1);
  xmax = sz(2);
  ymin = sz(3);
  ymax = sz(4);

  clf
  hold on

  % Color the elnod regions
  for i=[1:length(data.en.sf)]
    rectangle('Position',[data.en.sf(i), ymin, ...
          (data.en.ef(i)-data.en.sf(i)), (ymax-ymin)],...
        'FaceColor',[.9 1 .67],'EdgeColor','none')
  end

  % Color the load curve regions
  for i=[1:length(data.lc.sf)]
    rectangle('Position',[data.lc.sf(i), ymin, ...
          (data.lc.ef(i)-data.lc.sf(i)) (ymax-ymin)],...
        'FaceColor',[1 .88 0.67],'EdgeColor','none')
  end

  % Color the half-scan regions
  for i=[1:length(data.fs.sf)]
    rectangle('Position',[data.fs.sf(i), ymin, ...
          (data.fs.ef(i)-data.fs.sf(i)) (ymax-ymin)],...
        'FaceColor',[.69 .86 1],'EdgeColor','none')
  end

  % Then finally plot the actual data on top
  plot(data.d.mce0.data.fb(:,good_pixel))

  title(['Highlighted regions for pixel ' num2str(good_pixel)])
  xlabel('Timeseries (as data points)')
  ylabel('Feedback signal')

  hold off
end

