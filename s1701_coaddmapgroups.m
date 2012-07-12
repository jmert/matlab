function jobs=s1701_coaddmapgroups(bintype,binextra)
%jobs=s1701_coaddmapgroups()
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
    [taggroups,uid] = grouptags('cmb2012',{'has_tod'},bintype,binextra);

    keyboard
    taggroups = taggroups(end);

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

    % For each group, farm the job
    for i=1:length(taggroups)
        % Populate several variables which are going to be passed
        % along to the farm jobs
        thisgroup = taggroups{i};
        blocknum  = i;

        jobname = sprintf('block%03i', blocknum);
        jobs{end+1} = farmit('farmfiles',...
               's1701_coaddmapgroups_worker(thisgroup,blocknum,uid);',...
               'var',{'thisgroup','blocknum','uid'},...
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
        format  = '{ "name": "%s", "image": "%s", "tags": [ %s ] }';

        % The components which make up the JSON object
        name    = sprintf('Block #%03i', idx);
        imgfile = sprintf('%s_%03i.png', uid, idx);
        intags  = sprintf('"%s",', taggroups{idx}{:});
        intags  = intags(1:end-1); % Remove trailing ','

        objstr = sprintf(format, name, imgfile, intags);
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
    fid = fopen([uid '.js'], 'w');
    fprintf(fid, jsonstr);
    fclose(fid);
    % }}}
end

