function coaddopt=get_default_coaddopt(coaddopt)
%coaddopt=get_default_coaddopt(coaddopt)
%
%Fill any coadd options missing from INSTR with their default values
%
%INPUTS
%    COADDOPT   Input structure of coaddopt options
%
%OUTPUTS
%    COADDOPT   The full coaddopt structure for use by REDUC_COADDPAIRMAPS
%
%EXAMPLES
%    coaddopt = get_default_coaddopt( struct('sernum', '1701real') );
%    reduc_coaddpairmaps(tags, coaddopt);

    if ~exist('coaddopt','var')
        coaddopt = [];
    end
    if isempty(coaddopt)
        coaddopt = struct();
    end

    if ~isfield(coaddopt,'sernum')
        error('No serial number (mapopt.sernum) specified! Cannot proceed!')
    end

    if ~isfield(coaddopt,'coaddtype')
        coaddopt.coaddtype = 0;
    end
    if ~isfield(coaddopt,'jacktype')
        switch coaddopt.coaddtype
            case {0,1}
                coaddopt.jacktype = [0:8];  % Make all jackknives...
            otherwise
                coaddopt.jacktype = 0;      % ...unless coaddtype is per channel
        end
    end
    if ~isfield(coaddopt,'filt')
        coaddopt.filt = 'p3';
    end
    if ~isfield(coaddopt,'gs')
        coaddopt.gs = 1;
    end
    if ~isfield(coaddopt,'weight')
        coaddopt.weight = 3;
    end
    if ~isfield(coaddopt,'chflags')
        coaddopt.chflags = [];
    end
    if ~isfield(coaddopt,'proj')
        coaddopt.proj = 'radec';
    end
    if ~isfield(coaddopt,'cut')
        % If not specified, get standard cuts
        coaddopt.cut = get_default_round2_cuts();
    end
    if ~isfield(coaddopt,'daughter')
        coaddopt.daughter = 'a';
    end
    if ~isfield(coaddopt,'realpairmapset')
        % This is an "evil" option that could lead to confusion -- don't use it!
        coaddopt.realpairmapset = coaddopt.sernum(1:4);
    end
    if ~isfield(coaddopt,'tworound')
        coaddopt.tworound = 'normal';
    end
end
