function s1701_coaddmapgroups_worker(tags, blocknum)
%s1701_coaddmapgroups_worker
%
%The worker for S1701_COADDMAPGROUPS. This function should not be called
%directly, but rather from S1701_COADDMAPGROUPS which does the work of farming
%the files to the cluster.
%
%INPUTS
%    TAGS        A cell of tags which constitute a single group
%    BLOCKNUM    The block (group) number which will be used to identify this
%                run as well as label the output files and maps.

    % Set several "global" variables for use by this an any subfunctions
    sernum   = '1701real';
    mapopt   = get_default_mapopt( struct('sernum',sernum) );

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
    coaddopt.daughter  = sprintf('block%03i', blocknum);
    disp('Co-adding pairmaps...')
    reduc_coaddpairmaps(tags, coaddopt);

    %%%% Map file name generation
    % Do some nasty setup for generating the map file name. These bits have
    % been pulled from reduc_coaddpairmaps and may be subject to breaking if
    % the file structure is changed.
    if(coaddopt.gs == 1)
        gs = '_gs';
    else
        gs = '';
    end 
    if ~strcmp(coaddopt.proj,'radec')
        proj = ['_' coaddopt.proj];
    else
        proj = '';
    end
    if(coaddopt.coaddtype>0)
        coaddtype=sprintf('%1d',coaddopt.coaddtype);
    else
        coaddtype='';
    end

    fileext = sprintf('filt%s_weight%1d%s%s',...
                coaddopt.filt,coaddopt.weight,gs,proj);
    mapfile = sprintf('maps/%s/%s_%s_%s_jack%d%s.mat',...
                sernum(1:4),sernum(5:end),coaddopt.daughter,fileext,...
                coaddopt.jacktype,coaddtype);

    % Load the data and apply nominal calibrations
    data = load(mapfile);
    map = data.map; m = data.m;
    calfactor = get_ukpervolt();
    map = cal_coadd_maps(map, calfactor);

    % Now actually start plotting the the maps
    h = figure('Visible','off');
%    h = figure();
    colormap jet
    plotsize(h, 1300, 1900, 'pixels');

    subplot(3,1, 1);
    imagesc(m.x_tic, m.y_tic, map.T, [-250 250]);
    daspect([m.xdos m.ydos 1]);
    title('150 Ghz T (\muK)');
    xlabel('RA');
    ylabel('Dec');

    subplot(3,1, 2);
    imagesc(m.x_tic, m.y_tic, map.Q, [-250 250]);
    daspect([m.xdos m.ydos 1]);
    title('150 Ghz Q (\muK)');
    xlabel('RA');
    ylabel('Dec');
    
    subplot(3,1, 3);
    imagesc(m.x_tic, m.y_tic, map.U, [-250 250]);
    daspect([m.xdos m.ydos 1]);
    title('150 Ghz U (\muK)');
    xlabel('RA');
    ylabel('Dec');

    axes('Position',[.1 .1 .9 .85],'Visible','off');
    % Put the common colorbar off to the left
    caxis([-250 250]);
    colorbar('Location','WestOutside');

    % Then output the figure
    if ~exist('pagermaps','dir')
        mkdir('pagermaps')
    end
    outputfile = ['pagermaps/' coaddopt.daughter '.png'];
    export_fig('-png','-a2','-painters',outputfile)

    % Cleanup
    delete(h);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % AUXILIARY FUNCTIONS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

        % Finally, actually run the makepairmaps routine
        reduc_makepairmaps(gentags, mapopt);

    end %function s1701_prepare_pairmaps

end %function s1701_coaddmapgroups_worker
