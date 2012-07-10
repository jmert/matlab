function groups=grouptags(set,flags,divtype,extra)
%groups=grouptags(set,flags,divtype,extra)
%
%Separates tags into various groups based on a given criterion.
%
%INPUTS
%    SET        The tag set to use. This is passed directly to get_tags.
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
%OUTPUT
%    GROUPS     A cell array with each element a group. Each group is then a
%               a cell array of the constituent tags.
%
%EXAMPLE
%    groups = grouptags('cmb2012', {'has_tod'}, 'binned', 10);

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
    tags = get_tags(set, flags);

    % Now start divisioning them
    switch divtype
        case 'perdaydeck'
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
            end
        case 'binned'
            % If the extra data is not specified, assume we want to bin with
            % 10 tags at a time.
            if isempty(extra)
                extra = 10;
            end
            % Then make groups which are each extra tags in length
            while length(tags) > extra
                groups{end+1} = tags(1:extra);
                tags = tags((extra+1):end);
            end
            % Take up any extra stragglers
            if length(tags) > 0
                groups{end+1} = tags(1:end);
            end
        otherwise
            error('Unrecognized divisioning option');
    end
end
