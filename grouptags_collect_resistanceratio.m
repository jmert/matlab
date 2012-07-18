function grouptags_collect_resistanceratio(tags,outfile)
%grouptags_collect_resistanceratio(tags,outfile)
%
%Collect the information for the R_s and R_n values for a list of tags from
%their *_calval.mat files, and save the collated data to disk. This function is
%required to be run before GROUPTAGS with a binning type of 'resistanceratio'
%can be performed.
%
%INPUTS
%    TAGS   
%    OUTFILE   A filename specifying where to output the collected data.
%              Defaults to 'grouptags_resistanceratio.mat' in the current
%              directory.
%
%OUTPUTS
%    All output is saved to the output file.
%
%EXAMPLES
%    tags = get_tags('cmb2011',{'has_tod','has_cuts'});
%    outfile = 'grp_1701.mat';
%    grouptags_collect_resistanceratio(tags, outfile);
%    numbins = 10;
%    groups = grouptags('cmb2011', {'has_tod','has_cuts'},...
%                       'resistanceratio', numbins, outfile);
%

    if ~exist('outfile','var')
        outfile = [];
    end
    if isempty(outfile)
        outfile = 'grouptags_resistanceratio.mat';
    end

    % Preallocate the memory required to increase performance. Do this by
    % reading the first tag and copying the size of its structures.
    data = load_data(tags{1}, 'calval','lc');
    % First generate a prototype structure
    prototype = struct();
    prototype.lc   = data.lc;
    prototype.rsrn = zeros(size(data.lc.g,1), size(data.lc.g,2));
    prototype.rgl_rsrn = [];

    % Then allocate enough of them to store the info on all tags
    calvals = repmat(prototype, size(tags,1), size(tags,2));

    % Also get the list of files which get_array_info might read.
    info_files = dir('aux_data/fp_data/fp_data_bicep2_*.csv');
    info_files = {info_files(:).name};
    info_dates = cellfun(@(x) str2num(x(end-11:end-4)), info_files);
    % Append a large number to the end of the array which can never be exceeded
    info_dates = [info_dates 99999999];
    % Set to -1 to indicate uninitialized
    info_curr  = -1;
    p   = [];
    ind = [];

    fprintf('Collecting R_s/R_n values for %i tags...', length(tags));

    % Now for each tag, accumulate the required data.
    for i=1:length(tags)

        % Possibly reload the [p,ind] structures if necessary
        this_date = str2num(tags{i}(1:8));
        % The first time, do a kludge to capture which file was read
        if info_curr == -1
            info_curr = 1;
            [str,p,ind] = evalc(['get_array_info(''' tags{i} ''')']);
            loaded = regexp(str,'fp_data_bicep2_([0-9]{8}).csv','tokens');
            info_curr = find(str2num(loaded{1}{1}) == info_dates);
        % otherwise, just read in the new data and wait for the next file to
        % be needed
        elseif this_date >= info_dates(info_curr+1)
            info_curr = info_curr + 1;
            [p,ind] = get_array_info(tags{i});
        end

        % Now actually load the data and start calculating the relevant
        % quantities.
        data = load_data(tags{i}, 'calval', 'lc');
        calvals(i).lc = data.lc;

        % Calculate the R_s/R_n number for all channels
        calvals(i).rsrn = calvals(i).lc.g(:,:,4) ./ calvals(i).lc.g(:,:,3);
        % Then calculate the R_s/R_n mean for just the RGL channels for each
        % load curve independently
        calvals(i).rgl_rsrn = nanmean(calvals(i).rsrn(:,ind.rgl), 2);
    end

    save(outfile, 'tags', 'calvals');
end
