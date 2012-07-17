function [groups,uid]=grouptags(set,flags,divtype,extra)
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
%                   3. resistanceratio
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
%                   3. resistanceratio
%                      Scalar integer stating the number of bins to be created.
%                      All r values (see above for definition) should nominally
%                      exist between 0 and 1, and the value of EXTRA prescribes
%                      the number of bins within that ratio.
%                        NOTE: All tags which have r < 0 or r > 1 are
%                              automatically excluded.
%
%OUTPUT
%    GROUPS     A cell array with each element a group. Each group is then a
%               a cell array of the constituent tags.
%    UID        A unique string id which is constructed by the appropriate
%               divisioning algorithm. For example, the 'binned' type also takes
%               an extra integer, so it can return to the user a value of
%               'binned10' if the integer 10 was passed as extra data. This
%               allows for arbitrary formatting of more complex options.
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
                extra = 10;
            end
            % Call the helper to actually perform the binning
            groups = bintags(tags, extra);
            % Construct the unique string from 'binned' + the number of tags
            % combined for each bin.
            uid = sprintf('binned%i', extra);
        % }}}
        case 'resistanceratio' % {{{
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
%    farmsets = do_binning(alltags, 20);

    if ~isnumeric(binsize) || binsize < 0
        error('bintags: Invalid binning size');
    end

    groups = {};
    % Make groups which are each binsize in length
    while length(intags) > binsize
        groups{end+1} = intags(1:binsize);
        intags = tags((binsize+1):end);
    end
    % Take up any extra stragglers
    if length(intags) > 0
        groups{end+1} = tags(1:end);
    end
end

