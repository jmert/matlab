function jobs=s1701_coaddmapgroups(bintype,binextra)
%jobs=s1701_coaddmapgroups(bintype,binextra)
%
%Create a set of coadded maps based on different groupings of tags by farming
%the pairmap making, coadding, and plotting operations to the cluster.
%
%INPUTS
%    BINTYPE    The type of grouping to perform on the tags. See GROUPTAGS for
%               a list of the supported binning types.
%    BINEXTRA   The extra data to pass on to GROUPTAGS. See GROUPTAGS for more
%               information on this option.
%
%OUTPUTS
%    JOBS       A cell array of all the jobs which were submitted with FARMIT

    ARGS   = '';
    MEMORY = 6000;              % Specified in MB
    JOBLIM = 20;                % Concurrent nodes to run
    GROUP  = '/BICEP2_willmert/coaddmapgroups';
%    XHOSTS = {'airoldi03'};     % Hack to skip problematic hosts
    XHOSTS = {};

    jobs = {};

    % Retrieve all the tags which have been processed
    [taggroups,uid,auxdata] = grouptags({'cmb2010','cmb2011'},{'has_tod'},...
            bintype,binextra);

    %%%% Farming setup {{{
    % Ignore certain hosts if they're giving us problems.
    if length(XHOSTS) > 0
        ARGS = [ARGS ' -R "'];
        for i=1:length(XHOSTS)
            ARGS = [ARGS 'hname!=' XHOSTS{i}];
            if i~=length(XHOSTS)
                ARGS = [ARGS ' && '];
            end
        end
        ARGS = [ARGS '"'];
    end

    % Require enough memory for everything to run correctly
    ARGS = [ARGS sprintf(' -R rusage[mem=%d] -M %d',...
            MEMORY, MEMORY*1048.576)];

    % Be a nicer user by creating a job group and limiting the number of
    % concurrent jobs which can be run.
    system(['bgadd ' GROUP]);
    system( sprintf('bgmod -L %d %s', JOBLIM, GROUP) );
    % }}}

    %%% Extra information plotting {{{
    % Pass along a function handle which will do extra plotting depending on
    % the binning type which is chosen.
    switch bintype
        case 'rsrn'
            auxplot = '%s_%03i_rsrn.png';
            auxfn   = @plot_rsrn;
        otherwise
            auxplot = '';
            auxfn   = @plot_null;
    end
    % }}}

    % For each group, farm the job
    for i=1:length(taggroups)
        % Populate several variables which are going to be passed
        % along to the farm jobs
        thisgroup = taggroups{i};
        blocknum  = i;

        jobname = sprintf('block%03i', blocknum);
        jobs{end+1} = farmit('farmfiles',...
               's1701_coaddmapgroups_worker(thisgroup,blocknum,uid,auxfn,auxdata);',...
               'var',{'thisgroup','blocknum','uid','auxfn','auxdata'},...
               'jobname',jobname,...
               'group',GROUP,...
               'args',ARGS);

    end

    %%%% Metadata output {{{
    % Then write out some extra metadata which is used by the pager webpage to
    % properly display everything.
    %
    % NOTE: we assume here that all outputs are synchronized between here and
    %       the worker script. Make sure to change both functions if any changes
    %       are made.

    function objstr=printmetadata(idx)
        % The format of the JSON object which the pager expects for each block
        format = '{ "name": "%s", "image": "%s", "aux_image": %s, "tags": [ %s ] }';

        % The components which make up the JSON object
        name    = sprintf('Block #%03i', idx);
        imgfile = sprintf('%s_%03i.png', uid, idx);
        if ~isempty(auxplot)
            auximgfile = ['"' sprintf(auxplot, uid, idx) '"'];
        else
            auximgfile = 'undefined';
        end
        intags  = sprintf('"%s",', taggroups{idx}{:});
        intags  = intags(1:end-1); % Remove trailing ','

        objstr = sprintf(format, name, imgfile, auximgfile, intags);
    end

    % Make a JSON object for each tag group we processed
    indices = [1:length(taggroups)];
    lines   = arrayfun(@printmetadata, indices,'uniformoutput',false);
    % Then concatenate them together to make the bulk of the body
    body = sprintf('\t%s,\n', lines{:});
    body = body(1:end-2); % Remove the trailing ',\n'

    % Complete the output by combining the body with the header material
    % required to bring it all together.
    jsonstr = sprintf([...
            'blocks = [\n'...
            '\t{}, // Skip so that the array is 1-indexed\n'...
            '%s\n'... % The bulk contents
            '];'...
        ], body);

    % Write the output to the block.js file
    if ~exist('pagermaps','dir')
        mkdir('pagermaps')
    end
    fid = fopen(['pagermaps/' uid '.js'], 'w');
    fprintf(fid, jsonstr);
    fclose(fid);
    % }}}

    %%% The null plotting helper {{{
    function plot_null(thisgroup,blocknum,uid,auxdata)
    end
    % }}}

    %%% The R_s/R_n plotting helper {{{
    function plot_rsrn(thisgroup,blocknum,uid,auxdata)
        h = figure('Visible','off');
        plotsize(h, 1500, 400, 'pixels');
        set(h, 'DefaultAxesLooseInset',[0 0 0 0]);
        set(h, 'DefaultAxesFontSize', 10);
        setappdata(gcf, 'SubplotDefaultAxesLocation', [0.05, 0.15, 0.90, 0.75]);

        %%% Set the output in a 2/3 1/3 plot: a timeseries of the R_s/R_n
        %%% values on the left 2/3, and a histogram of all values on the right
        %%% 1/3.

        minrsrn = min(auxdata.rsrn_groups{blocknum});
        maxrsrn = max(auxdata.rsrn_groups{blocknum});
        avgrsrn = mean(auxdata.rsrn_groups{blocknum});

        % Plot the time series
        subplot(1,3,[1 2])
        plot(auxdata.allrsrn,'Color',[0.75 0.75 0.75]);
        title('\fontsize{12}R_s/R_n for the 2010 and 2011 seasons','interpreter','tex');
        xlabel('Time [MM/DD]');
        ylabel('R_s/R_n','interpreter','tex');
        % Have the limits correspond to the data limits
        xlim([0,size(auxdata.allrsrn,2)]);
        % Construct the x-axis labels from the tag dates which correspond to
        % the tick marks automatically chosen.  The +1 is necessary to go
        % from 0-indexed limits to 1-index arrays
        xticks = get(gca, 'XTick');
        xlabs  = auxdata.alltags(xticks+1);
        xlabs  = cellfun(@(x) [x(5:6) '/' x(7:8)],xlabs,'UniformOutput',false);
        set(gca, 'XTickLabel', xlabs);
        % Then make markers showing where the current set of data came from
        % within the timeseries
        hold on;
        xpts = auxdata.indx_groups{blocknum};
        ypts = auxdata.allrsrn(xpts);
        plot(xpts, ypts, 'r.');
        % Add a label to the graph giving the average R_s/R_n value for this
        % plot
        text('Units','normalized', 'Position',[0.05 0.1],'Color','r',...
             'String',sprintf('\\langleR_s/R_n\\rangle = %f',mean(avgrsrn))...
            );
        hold off;

        % Plot the histogram of R_s/R_n values
        subplot(1,3,3)
        [n,x] = hist(auxdata.allrsrn(1,:),100);
        stairs(x,n,'Color','k');
        title('\fontsize{12}Distribution of R_s/R_n','interpreter','tex');
        xlabel('R_s/R_n','interpreter','tex');
        ylabel('Frequency');
        hold on
        xlim([0.5 1]);
        % Also draw the range of R_s/R_n values on the histogram as two
        % vertical lines moving across histogram
        ypts = ylim;
        xpts = [minrsrn minrsrn];
        line(xpts,ypts,'color','r','linestyle','-.');
        xpts = [maxrsrn maxrsrn];
        line(xpts,ypts,'color','r','linestyle','-.');
        hold off

        % Save the plot
        if ~exist('pagermaps','dir')
            mkdir('pagermaps')
        end
        outputfile = sprintf(['pagermaps/' auxplot], uid, blocknum);
        mkpng(outputfile, true);

        % Cleanup
        delete(h);
    end
    % }}}
end

