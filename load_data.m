function data=load_data(tag, product, vars, varargin)
%data=load_data(tag, product, varargin)
%
%Load various data products in the pipeline based on tag name without the need
%to generate the path names manually.
%
%INPUTS
%    TAG        A tag string identifying the data to be loaded.
%    PRODUCT    One of the data products which are saved by the pipeline. A
%               complete list of valid data products are listed below in the
%               DATA PRODUCTS section.
%    VARS       A cell array of the variables which are to be loaded from the
%               data product.
%    VARARGIN   A position-dependent list of extra parameters which may be
%               necessary depending on the product files to be loaded. See
%               the DATA PRODUCTS section below for a complete description.
%
%OUTPUTS
%    DATA       A structure of the variables saved within the requested data
%               file.
%
%EXAMPLES
%    mapopt = get_default_mapopt( struct('sernum',1701) );
%    mapdat = load_data('20100424E04_dk068', 'map', mapopt);
%    imagesc(mapdat.map.T);
%
%DATA PRODUCTS
%    A specific data product is loaded by passing an appropriate named to
%    PRODUCT. Depending on the product, some extra information may be required
%    to load the data: this data is passed as position-independent parameters
%    following PRODUCT in the call.
%
%    The following data products are currently supported and can be used as a
%    string parameter for PRODUCT:
%
%        calval    Computed calibration factors
%
%
%    The following listing describes any position-dependent parameters required
%    for the corresponding data product loading:
%
%        calval
%            None
%
%NOTES
%    1. LOAD_DATA will warn if any variables listed in VARS are unknown for the
%       corresponding data product file, but the variable name is still passed
%       to the LOAD call. The warning for unknown variables from LOAD is
%       suppressed since LOAD_DATA already warns of this. Therefore, check to
%       make sure that the variable has actually been loaded before using to
%       be sure.
%

    % Put a list of constants at the top of the function so that any changes
    % can be quickly implemented without having to search the function for
    % all relevant uses of a constant string.

    % Initial subdirectory path of each data product
    PATH_CALDAT = 'data/real/';

    % Initialize the vars to all vars (with '*') if none are given
    if ~exist('vars', 'var')
        vars = [];
    end
    if isempty(vars)
        vars = {'*'};
    elseif ischar(vars)
        vars = cellstr(vars);
    end

    % Disable the variableNotFound errors from the load command since we're
    % already warning about these with more specific information
    warnstate = warning('off', 'MATLAB:load:variableNotFound');

    switch product
        % The general structure of each case should be
        %     1. Check the list of requested vars with check_vars()
        %     2. Build a path to the file
        %     3. Load the data products and return

        case 'calval' % {{{
            check_vars(vars, {'code_dir','en','lc','fs'});

            filename = [PATH_CALDAT tag '_calval.mat'];

            data = load('-mat', filename, vars{:});
        % }}}
        otherwise
            error(['load_data: Unknown product type ''' product '''.']);
    end

    % Restore the warning state
    warning(warnstate);

    function check_vars(request, known) % {{{
        % Find the intersection of the requested variables with the list of
        % known variables, including the default wildcard
        [inter,idxreq,idxknw] = intersect(request, {'*',known{:}} );
        % Then remove any known vars from the requested list
        request(idxreq) = [];
        % If there are any remaining variables being requested, then warn
        % the user.
        if length(request) > 0
            % Trick to turn the array of variables into a comma separated list
            % in a single string, ready for printing.
            request = [request; [repmat({','},length(request)-1), {''}] ];
            request = request(:)';
            request = horzcat(request{:});

            warnstr = sprintf(...
                'Unknown variable(s) ''%s'' for product type ''%s''.',...
                request,product);
            disp(['Warning: ' warnstr]);
        end
    end % }}}
end

