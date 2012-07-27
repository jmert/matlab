function s1701_coaddmapgroups_worker(tags, blocknum, prefix, auxfn, auxdata)
%s1701_coaddmapgroups_worker(tags, blocknum, prefix, auxfn, auxdata)
%
%The worker for S1701_COADDMAPGROUPS. This function should not be called
%directly, but rather from S1701_COADDMAPGROUPS which does the work of farming
%the files to the cluster.
%
%INPUTS
%  TAGS        A cell of tags which constitute a single group
%  BLOCKNUM    The block (group) number which will be used to identify this
%              run as well as label the output files and maps.
%  PREFIX      The file name prefix to use for the output of all maps. Each
%              will be saved with the name according to
%                  sprintf('%s_%03i.png', PREFIX, BLOCKNUM)
%  AUXFN       A function handle to an auxiliary plotting function. This
%              allows for a generic farming script despite wanting binning
%              type-specific plotting.
%  AUXDATA     Auxiliary data which is used by the function given in AUXFN.
%              The data should be the output data from GROUPTAGS.

  %%%% Initialize a bunch of variables {{{
  % Set several "global" variables for use by this an any subfunctions
  CBARRANGE   = [-250 250];
  sernum_real = '1701real';
  sernum_simQ = '17019902';
  sernum_simV = '17019912';
  wmapQ  = 'justus_wmap/wmap_band_iqumap_r9_5yr_Q_v3_bicep2ideal.fits';
  wmapV  = 'justus_wmap/wmap_band_iqumap_r9_5yr_V_v3_bicep2ideal.fits';
  mapopt = get_default_mapopt( struct('sernum',sernum_real) );
  % Initialize the simopt to deal with WMAP data
  simopt.beamwid    = 'zero';
  simopt.beamcen    = 'obs';
  simopt.polpair    = 'ideal';
  simopt.diffpoint  = 'ideal';
  simopt.sigmaptype = 'healmap';
  simopt.siginterp  = 'healpixnearest';
  simopt.noise      = 'none';
  simopt.sig        = 'normal';
  simopt.type       = 'bicep';
  simopt.ukpervolt  = 1;
  simopt.interpix   = 0.25;
  simopt.maketod    = 0;
  % And generate the corresponding coaddopt to match the defaults in the mapopt
  coaddopt.jacktype  = 0;
  coaddopt.coaddtype = 0;
  coaddopt.filt      = mapopt.filt;
  coaddopt.weight    = 3;
  coaddopt.gs        = mapopt.gs;
  coaddopt.proj      = mapopt.proj;
  coaddopt.daughter  = sprintf('%s_%03i', prefix, blocknum);
  %%%% End variable initialization }}}

  %%%% Generate the real and simulated pairmaps {{{
  disp('Initializing real pairmaps...')
  mapopt = get_default_mapopt( struct('sernum',sernum_real) );
  real_tags = filter_existing_pairmaps(tags, mapopt);
  % Make each pairmap individually even though reduc_makepairmaps can take a
  % cell array so that on failure, we can output some extra information to the
  % log file (captured from stderr by farmit).
  for i=1:length(real_tags)
    try
      reduc_makepairmaps(real_tags(i), mapopt);
    catch ex
      fprintf(2,'%s', getReport(ex));
      fprintf(2,'TagError:%s\n', real_tags{i});
    end
  end

  disp('Initializing WMAP Q pairmaps...')
  % Reset some necessary fields in the data structures
  mapopt = get_default_mapopt( struct('sernum',sernum_simQ) );
  simopt.sigmapfilename = wmapQ;
  simopt.sernum         = sernum_simQ;
  simopt.mapopt         = {mapopt};
  % Get the list of tags to be generated and do so
  wmapQ_tags = filter_existing_pairmaps(tags, mapopt);
  for i=1:length(wmapQ_tags)
    try
      reduc_makesim(wmapQ_tags(i), simopt);
    catch ex
      fprintf(2,'%s', getReport(ex));
      fprintf(2,'SimError:%s\n', wmapQ_tags{i});
    end
  end

  disp('Initializing WMAP V pairmaps...')
  % Reset some necessary fields in the data structures
  mapopt = get_default_mapopt( struct('sernum',sernum_simV) );
  simopt.sigmapfilename = wmapV;
  simopt.sernum         = sernum_simV;
  simopt.mapopt         = {mapopt};
  % Now actually get which tags need to be simulated and do so
  wmapV_tags = filter_existing_pairmaps(tags, mapopt);
  for i=1:length(wmapV_tags)
    try
      reduc_makesim(wmapV_tags(i), simopt);
    catch ex
      fprintf(2,'%s', getReport(ex));
      fprintf(2,'SimError:%s\n', wmapV_tags{i});
    end
  end

  % Release some unneeded memory held in various variables
  clear real_tags wmapQ_tags wmapV_tags
  %%%% end pairmaps }}}

  %%%% Coadd all the corresponding maps {{{
  disp('Co-adding real pairmaps...')
  coaddR = coaddopt;
  coaddR.sernum = sernum_real;
  reduc_coaddpairmaps(tags, coaddR);

  disp('Co-adding WMAP Q pairmaps...')
  coaddQ = coaddopt;
  coaddQ.sernum = sernum_simQ;
  reduc_coaddpairmaps(tags, coaddQ);

  disp('Co-adding WMAP V pairmaps...')
  coaddV = coaddopt;
  coaddV.sernum = sernum_simV;
  reduc_coaddpairmaps(tags, coaddV);
  %%%% end coadd }}}

  %%%% Do the absolute calibration {{{
  qmap = get_data_path([],'map',coaddR);
  rmap = get_data_path([],'map',coaddQ);
  cmap = get_data_path([],'map',coaddV);
  % reduc_abscal currently add the 'maps/' prefix to the file names given
  % which get_data_path also does, so fix the paths by cutting the first
  % 5 characters away;
  qmap = qmap(6:end);
  rmap = rmap(6:end);
  cmap = cmap(6:end);
  % Then actually run the calibration
  [ukpervolt,aps] = reduc_abscal(qmap, rmap, cmap, 'wmapqv', 0);
  % }}}

  %%%% Now actually start plotting the the maps {{{
  h = figure('Visible','off');
  colormap jet
  plotsize(h, 1500, 1000, 'pixels');

  % Set a bunch of defaults
  set(h, 'DefaultAxesLooseInset',[0 0 0 0]);
  set(h, 'DefaultAxesCLim', CBARRANGE);
  set(h, 'DefaultAxesFontSize', 10);
  setappdata(gcf, 'SubplotDefaultAxesLocation', [0.01, 0.08, 0.98, 0.85]);

  % Load the real and apply the nominal calibration factor.
  % Since we already chopped off the 'maps/' part, re-add it here
  data = load(['maps/' qmap], 'm','map');
  map = data.map; m = data.m;
  calfactor = get_ukpervolt();
  map = cal_coadd_maps(map, calfactor);
  % Plot T
  Tax = subplot(3,3, 1);
  imagesc(m.x_tic, m.y_tic, map.T, CBARRANGE);
  Taxbar = colorbar('eastoutside');
  title(sprintf('150 Ghz T (\\muK) [%d \\muK/V]', calfactor));
  xlabel('RA');
  ylabel('Dec');
  % Plot Q
  Qax = subplot(3,3, 2);
  imagesc(m.x_tic, m.y_tic, map.Q, CBARRANGE);
  Qaxbar = colorbar('eastoutside');
  title('Real 150 Ghz Q (\muK)');
  xlabel('RA');
  ylabel('Dec');
  % Plot U
  Uax = subplot(3,3, 3);
  imagesc(m.x_tic, m.y_tic, map.U, CBARRANGE);
  Uaxbar = colorbar('eastoutside');
  title('Real 150 Ghz U (\muK)');
  xlabel('RA');
  ylabel('Dec');

  % Now replot the T map using the newly determined calibration factor instead
  map = data.map;
  map = cal_coadd_maps(map, ukpervolt);
  realax = subplot(3,3, 4);
  imagesc(m.x_tic, m.y_tic, map.T, CBARRANGE);
  realaxbar = colorbar('eastoutside');
  title(sprintf('150 Ghz T (\\muK) [%4.0f \\muK/V]', ukpervolt));
  xlabel('RA');
  ylabel('Dec');
  % Then also plot the reference and calibration maps
  % Reference map
  data = load(['maps/' rmap], 'm','map');
  map = data.map; m = data.m;
  refax = subplot(3,3, 5);
  imagesc(m.x_tic, m.y_tic, map.T, CBARRANGE);
  refaxbar = colorbar('eastoutside');
  title('WMAP Q Band Reference');
  xlabel('RA');
  ylabel('Dec');
  % Calibration map
  data = load(['maps/' cmap], 'm','map');
  map = data.map; m = data.m;
  calax = subplot(3,3, 6);
  imagesc(m.x_tic, m.y_tic, map.T, CBARRANGE);
  calaxbar = colorbar('eastoutside');
  title('WMAP V Band Calibration');
  xlabel('RA');
  ylabel('Dec');

  % Plot the extra information from cross spectrum analysis
  subplot(3,3, 7);
  plot(aps(1,1).l,[aps(1,:).rxc],'.-')
  title('150GHz ref x cal');
  xlabel('ell');
  ylabel('xspec');

  subplot(3,3, 8);
  plot(aps(1,1).l,[aps(1,:).rxq],'.-')
  title('150GHz ref x data');
  xlabel('ell');
  ylabel('xspec');

  subplot(3,3, 9);
  plot(aps(1,1).l,[aps(1,:).cal],'.-');
  title('150GHz cal factors');

  % Also call the auxiliary plotting function
  auxfn(tags,blocknum,prefix,auxdata);
  %%%% End plotting }}}

  %%%% Then output the figure {{{
  if ~exist('pagermaps','dir')
    mkdir('pagermaps')
  end
  outputfile = ['pagermaps/' coaddopt.daughter '.png'];
  mkpng(outputfile, true);
  %%%% End outputing }}}

  % Cleanup
  delete(h);

  %%% AUXILIARY FUNCTIONS {{{
  function gentags=filter_existing_pairmaps(tags, mapopt)
    % Generate the pairmap file names
    fnames = get_pairmap_filename(tags, mapopt);
    % Then determine which ones need to be generated.
    mask = cellfun(@(x) ~exist(x,'file'), fnames);

    % Extract the tags which need to be generated. If none do, then just
    % return
    gentags = tags(mask);
  end
  %%%% End aux functions }}}

end %function s1701_coaddmapgroups_worker
