function [groups,uid,data]=grouptags(set,flags,divtype,extra)
%[groups,uid]=grouptags(set,flags,divtype,extra)
%
%Separates tags into various groups based on a given criterion.
%
%INPUTS
%    SET        The tag set to use. If a single string, this is passed directly
%               to GET_TAGS, otherwise a cell array is looped over and each
%               return from GET_TAGS is appended to the internal list in order.
%    FLAGS      The flags which are passed onto get_tags.
%    DIVTYPE    The method of dividing the retrieved tags into groups. Currently
%               implemented are the options:
%
%                   1. perdaydeck [default]
%                      This method tries to identify complete runs of the
%                      telescope and groups the tags together to comprise a
%                      complete run. For BICEP2, this should be 67 tags per
%                      group in the 2012 season, but various errors can make
%                      this number fluctuate. Sets are identified by grouping
%                      contiguous runs of a single deck angle within the list of
%                      tags returned by GET_TAGS.
%
%                   2. binned
%                      Simple binning where each block of N tags are taken
%                      together. The last group returned may have a variable
%                      number of tags in the group since the total number of
%                      tags may not be evenly divisible by N. See the EXTRA
%                      option for more information.
%
%                   3. rsrn
%                      Takes the ratio of the operating resistance of the
%                      detectors versus their resistance in the normal state
%                      to derive the ratio r = R_s / R_n. The value is derived
%                      from reading in all corresponding *_calval.mat files.
%                      Once collected, the tags are then sorted by r and binned
%                      according to the value passed into EXTRA.
%
%    EXTRA      Any extra information which may necessary for one of the
%               binning algorithms described above.
%
%                   1. perdaydeck
%                      None. Any data passed in is ignored.
%
%                   2. binned
%                      Scalar integer expected which prescribes N, the number
%                      of tags to be placed in each bin.
%
%                   3. rsrn
%                      A scalar integer stating the size of bins to be created.
%                      All r values (see above for definition) should nominally
%                      exist between 0 and 1.
%                        NOTE: All tags which have r < 0 or r > 1 are
%                        automatically excluded.
%
%OUTPUT
%    GROUPS     A cell array with each element a group. Each group is then a
%               a cell array of the constituent tags.
%    UID        A unique string id which is constructed by the appropriate
%               divisioning algorithm. For example, the 'binned' type also takes
%               an extra integer, so it can return to the user a value of
%               'binned10' if the integer 10 was passed as extra data. This
%               allows for arbitrary formatting of more complex options.
%    DATA       An output of any extra information which may be useful to the
%               caller. This will typically hold information which was used to
%               perform the various binning processes.
%
%                   1. perdaydeck
%                      None
%
%                   2. binned
%                      None
%
%                   3. rsrn
%                      A structure containing the following members:
%                        a. prob_tags
%                           List of tags removed because the tag does not have
%                           exactly two partial load curves.
%                        b. nans
%                           List of tags removed because r = NaN.
%                        c. ltzero
%                           List of tags removed because r < 0.
%                        d. gtone
%                           List of tags removed because r > 0.
%                        e. rsrn_groups
%                           Cell array of groups of R_s/R_n values corresponding
%                           to each group output in GROUPS.
%                        f. indx_groups
%                           Group of index arrays into ALLTAGS and ALLRSRN which
%                           correspond to each group in GROUPS.
%                        g. alltags
%                           The list of all tags in chronological order
%                        h. allrsrn
%                           The array of all r values in chronological order.
%
%EXAMPLE
%    [groups,uid] = grouptags('cmb2012', {'has_tod'}, 'binned', 10);

    if ~exist('divtype','var')
        divtype = [];
    end
    if isempty(divtype)
        divtype = 'perdaydeck';
    end

    if ~exist('extra','var')
        extra = [];
    end

    groups  = {};
    data    = struct();

    % Start by getting a list of all tags using
    tags = {};
    if ~iscell(set)
        tags = get_tags(set, flags);
    else
        for i=1:length(set)
            tags = [tags get_tags(set{i}, flags)];
        end
    end

    % Now start divisioning them
    switch divtype
        case 'perdaydeck' % {{{
            while length(tags) > 0
                % Get the first deck angle
                deck = tags{1}((end-4):end);
                % Then produce a mask of all tags which match the given deck
                % angle.
                matches = ~cellfun(@isempty, strfind(tags, deck));
                % Now adapt the logic of find_blk to get the first contiguous
                % block of tags.
                diffs = diff([0 matches 0]);
                start = find(diffs==1, 1);
                ends  = find(diffs==-1, 1) - 1;
                % Save the group
                groups{end+1} = tags(start:ends);
                % Then delete the group we just saved and repeat
                tags = tags((ends(1)+1):end);

                % Also remember to set the unique string. Since there are no
                % options here, just return 'perdaydeck'
                uid = 'perdaydeck';
            end
        % }}}
        case 'binned' % {{{
            % If the extra data is not specified, assume we want to bin with
            % 10 tags at a time.
            if isempty(extra)
                disp('grouptags [binned]: Defaulting to 10 bins');
                extra = 10;
            end
            % Call the helper to actually perform the binning
            groups = bintags(tags, extra);
            % Construct the unique string from 'binned' + the number of tags
            % combined for each bin.
            uid = sprintf('binned%i', extra);
        % }}}
        case 'rsrn' % {{{
            % First verify that our inputs are correct. No use in continuing
            % if the operation will fail later.
            if isempty(extra)
                disp('grouptags [rsrn]: Defaulting to 250 bins');
                extra = 250;
            end
            if ~isnumeric(extra)
                error('grouptags [rsrn]: Number of bins must be an integer');
            end


            if ~exist('grouptags_rsrn.mat','file')
                % If no save file exists, just generate the data
                grouptags_collect_rsrn(tags);
            else
                % Otherwise if it does, see if we can short-circuit this step
                % by first loading only the tags and seeing if they correspond
                % with each other. If they do, then we can again assume the
                % data is OK.
                saved = load('grouptags_rsrn.mat','tags');
                % Compare the lengths of each string first, then if they are
                % the same, continue by comparing each string. If no match
                % returns a false, then we can skip this step
                if length(saved.tags) ~= length(tags) || ...
                   length(find(cellfun(@isequal,saved.tags,tags)==false)) ~= 0
                    grouptags_collect_rsrn(tags);
                end
                saved = [];
            end

            % Now load all up-to-date data and start binning
            datfile = load('grouptags_rsrn.mat');
            initcount = size(datfile.tags,2);

            % For now, ignore any tags which did not have two load curves (and
            % therefore don't have two rgl_rsrn values). Also save the problem
            % tags the output data structure.
            sizes = arrayfun(@(x) size(x.lc.g,1), datfile.calvals);
            probs = find(sizes ~= 2);
            data.prob_tags = datfile.tags(probs);
            datfile.tags(probs)    = [];
            datfile.calvals(probs) = [];

            % Collect all rgl_rsrn values into a 2xX array
            tags = datfile.tags;
            rsrn = [datfile.calvals(:).rgl_rsrn];

            % Remove entries with NaN values and r<0 or r>1
            nans   = [ find(isnan(rsrn(1,:))) , find(isnan(rsrn(2,:))) ];
            ltzero = [ find(rsrn(1,:) < 0) , find(rsrn(2,:) < 0) ];
            gtone  = [ find(rsrn(1,:) > 1) , find(rsrn(2,:) > 1) ];
            rmall  = [ nans ltzero gtone ];
            data.nans   = tags(nans);
            data.ltzero = tags(ltzero);
            data.gtone  = tags(gtone);
            tags(rmall)   = [];
            rsrn(:,rmall) = [];

            finalcount = size(tags,2);
            fprintf(['%i (%2.2f%%) tags remain after filtering:\n'...
                     '\tN ~= 2: %i\n'...
                     '\t NaN''s: %i\n'...
                     '\t r < 0: %i\n'...
                     '\t r > 1: %i\n'],...
                    finalcount, 100*finalcount/initcount,...
                    length(probs),length(nans),length(ltzero),length(gtone));

            % Sort the R_s/R_n values so that we can division them into equally
            % sized groups.
            [rsrn_sorted1,perm1] = sort(rsrn(1,:));
            [rsrn_sorted2,perm2] = sort(rsrn(2,:));
            tags1 = tags(perm1);
            tags2 = tags(perm2);

            % Then split the list of tags into binned groups
            groups = bintags(tags1, extra);
            % Also reuse the machinery of bintags to create corresponding
            % groups of the R_s/R_n values and their indices into the allrsrn
            % array
            data.rsrn_groups = bintags(rsrn_sorted1, extra);
            data.indx_groups = bintags(perm1, extra);

            % Save all tags and R_s/R_n values to the extra data array.
            data.alltags = tags;
            data.allrsrn = rsrn(1,:);

            % Finally, construct the string identifier for this type of binning
            uid = sprintf('rsrn%i',extra);
        % }}}
        otherwise
            error('Unrecognized divisioning option');
    end

end

function groups=bintags(intags, binsize)
%groups=bintags(intags, binsize)
%
%Divides a list of tags into a number of groups of a given bin size.
%
%The ability to simply bin a list of tags together into a set of groups is
%generically useful (i.e. for farming operations across a cluster), so the
%function is exposed for use by other grouping algorithms as a helper function.
%
%INPUTS
%    INTAGS       List of input tags to operate upon
%    BINSIZE      Size of each bin to generate
%
%OUTPUT
%    BINNEDGRPS   The output cell array of groups of tags
%
%EXAMPLE
%    farmsets = bintags(alltags, 20);

    if ~isnumeric(binsize) || binsize < 0
        error('bintags: Invalid binning size');
    end

    groups = {};
    % Make groups which are each binsize in length
    while length(intags) > binsize
        groups{end+1} = intags(1:binsize);
        intags = intags((binsize+1):end);
    end
    % Take up any extra stragglers
    if length(intags) > 0
        groups{end+1} = intags(1:end);
    end
end

