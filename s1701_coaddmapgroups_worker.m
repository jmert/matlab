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

  % Set several "global" variables for use by this an any subfunctions
  CBARRANGE = [-250 250];
  sernum    = '1701real';
  mapopt    = get_default_mapopt( struct('sernum',sernum) );

  disp('Initializing pairmaps...')
  s1701_prepare_pairmaps(tags);

  % Setup the coadd options structure to ensure a match with the defaults
  % used by reduc_makepairmaps
  coaddopt.sernum    = sernum;
  coaddopt.jacktype  = 0;
  coaddopt.coaddtype = 0;
  coaddopt.filt      = mapopt.filt;
  coaddopt.weight    = 3;
  coaddopt.gs        = mapopt.gs;
  coaddopt.proj      = mapopt.proj;
  coaddopt.daughter  = sprintf('%s_%03i', prefix, blocknum);
  disp('Co-adding pairmaps...')
  reduc_coaddpairmaps(tags, coaddopt);

  % Load the data and apply nominal calibrations
  data = load_data('','map',{'m','map'},coaddopt);
  map = data.map; m = data.m;
  calfactor = get_ukpervolt();
  map = cal_coadd_maps(map, calfactor);

  %%%% Now actually start plotting the the maps {{{
  h = figure('Visible','off');
  colormap jet
  plotsize(h, 1500, 300, 'pixels');

  % Set a bunch of defaults
  set(h, 'DefaultAxesLooseInset',[0 0 0 0]);
  set(h, 'DefaultAxesCLim', CBARRANGE);
  set(h, 'DefaultAxesFontSize', 10);
  setappdata(gcf, 'SubplotDefaultAxesLocation', [0.03, 0.05, 0.92, 0.85]);

  % Plot T
  Tax = subplot(1,3, 1);
  imagesc(m.x_tic, m.y_tic, map.T, CBARRANGE);
  Taxbar = colorbar('eastoutside');
  title('150 Ghz T (\muK)');
  xlabel('RA');
  ylabel('Dec');

  % Plot Q
  Qax = subplot(1,3, 2);
  imagesc(m.x_tic, m.y_tic, map.Q, CBARRANGE);
  Qaxbar = colorbar('eastoutside');
  title('150 Ghz Q (\muK)');
  xlabel('RA');
  ylabel('Dec');

  % Plot U
  Uax = subplot(1,3, 3);
  imagesc(m.x_tic, m.y_tic, map.U, CBARRANGE);
  Uaxbar = colorbar('eastoutside');
  title('150 Ghz U (\muK)');
  xlabel('RA');
  ylabel('Dec');

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
  function s1701_prepare_pairmaps(tags)
  %s1701_prepare_pairmaps
  %
  %Populate pairmaps/1701/real with pair maps for all tags contained in TAGS
  %if they do not already exist.
  %
  %INPUTS
  %    TAGS    A cell array containing a list of tags

    % Generate the pairmap file names
    fnames = get_pairmap_filename(tags, mapopt);
    % Then determine which ones need to be generated.
    mask = cellfun(@(x) ~exist(x,'file'), fnames);

    % Extract the tags which need to be generated. If none do, then just
    % return
    gentags = tags(mask);
    if length(gentags) < 1
      return
    end

    % Finally, actually run the makepairmaps routine. Do each one
    % individually even though reduc_makepairmaps can take a cell array
    % so that on failure, we can output some extra information to the
    % log file (captured from stderr by farmit).
    for i=1:length(gentags)
      try
        reduc_makepairmaps(gentags(i), mapopt);
      catch ex
        fprintf(2,'%s', getReport(ex));
        fprintf(2,'TagError:%s\n', gentags{i});
      end
    end
  end %function s1701_prepare_pairmaps
  %%%% End aux functions }}}

end %function s1701_coaddmapgroups_worker
