function data=load_data(tag, product, vars, varargin)
%data=load_data(tag, product, vars, varargin)
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
%    cals = load_data('20100424E04_dk068', 'calval', {'en','lc'});
%      - or -
%    mapdat = load_data('', 'map', '*', coaddopt);
%    imagesc(mapdat.map.T);
%
%DATA PRODUCTS
%  A specific data product is loaded by passing an appropriate named to
%  PRODUCT. Depending on the product, some extra information may be required to
%  load the data: this data is passed as position-dependent parameters
%  following PRODUCT in the call.
%
%  The following data products are currently supported and can be used as a
%  string parameter for PRODUCT:
%
%    calval    Computed calibration factors
%    map       Coadded maps
%    tod       Raw time-ordered-data stream
%
%
%  The following listing describes any position-dependent parameters required
%  for the corresponding data product loading. If an extra parameter is needed,
%  remember to fill in VARS with either {'*'} or [] to load all data or the
%  list of desired variables.
%
%    calval
%      None
%    map
%      1. coaddopt
%         Data structure with same form as passed into the REDUC_COADDPAIRMAP
%         function. The field SERNUM must contain a serial number as usual, and
%         the JACKTYPE field must be a single scalar (the default coaddopt
%         specifies all jackknife types) since a given map type must be chosen.
%      -- NOTE: The map type does not directly use a tag value anywhere in
%         choosing the file to load, so here an empty string is permitted.
%    tod
%      None
%
%NOTES
%  1. LOAD_DATA will warn if any variables listed in VARS are unknown for the
%     corresponding data product file, but the variable name is still passed to
%     the LOAD call. The warning for unknown variables from LOAD is suppressed
%     since LOAD_DATA already warns of this. Therefore, check to make sure that
%     the variable has actually been loaded before using to be sure.
%

  % Put a list of constants at the top of the function so that any changes can
  % be quickly implemented without having to search the function for all
  % relevant uses of a constant string.

  % Get the initial number of input arguments
  numargin = nargin;

  % Initialize the vars to all vars (with '*') if none are given
  if ~exist('vars', 'var')
    vars = [];
    numargin = numargin + 1;
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
    %   1. Verify number of extra parameters passed in
    %   2. Check the list of requested vars with check_vars()
    %   3. Build a path to the file
    %   4. Load the data products and return

    case 'calval' % {{{
      check_nargin(numargin, 0, 'calval');
      check_vars(vars, {'code_dir','en','lc','fs'});

      filename = ['data/real/' tag '_calval.mat'];

      data = load('-mat', filename, vars{:});
    % }}}
    case 'map' % {{{
      check_nargin(numargin, 1, 'map');
      check_vars(vars, {'coaddopt','m','map'});

      % We require at least a serial number to exist within the coaddopt struct
      % since it is always a requirement
      coaddopt = varargin{1};
      if ~isstruct(coaddopt)
        error('load_data [map]: ''map'' expects a coaddopt struct');
      end
      if ~isfield(coaddopt,'sernum')
        error(['load_data [map]: Serial number (coaddopt.sernum) '...
             'must be given.']);
      end
      % Then use the get_default_coaddopt function to combine the given
      % structure with the required structure members.
      coaddopt = get_default_coaddopt(coaddopt);

      % If there is more than one jacktype at this stage, we also must bail
      % since we don't know which one we should load.
      if length(coaddopt.jacktype) > 1
        error(['load_data [map]: Only one jackknife type '...
             '(coaddopt.jacktype) can be given.']);
      end

      % Then build the strings required to build the full path. Taken directly
      % from reduc_coaddpairmaps
      if iscell(coaddopt.filt)
        filt = [coaddopt.filt{:}];
      else
        filt = coaddopt.filt;
      end
      if coaddopt.gs == 1
        gs = '_gs';
      else
        gs = '';
      end
      if ~strcmp(coaddopt.proj,'radec')
        proj = ['_' coaddopt.proj];
      else
        proj = '';
      end
      if coaddopt.coaddtype > 0
        coaddtype=sprintf('%1d',coaddopt.coaddtype);
      else
        coaddtype='';
      end

      fileext = sprintf('filt%s_weight%1d%s%s',...
            filt,coaddopt.weight,gs,proj);
      filename = sprintf('maps/%s/%s_%s_%s_jack%d%s.mat',...
            coaddopt.sernum(1:4),coaddopt.sernum(5:end),...
            coaddopt.daughter,fileext,...
            coaddopt.jacktype,coaddtype);

      % Finally load the data
      data = load('-mat', filename, vars{:});
    % }}}
    case 'tod' % {{{
      check_nargin(numargin, 0, 'tod');
      check_vars(vars, {'d','dg','ds','en','fs','fsb','lc','pm'});

      filename = ['data/real/' tag '_tod.mat'];

      data = load('-mat', filename, vars{:});
    % }}}
    otherwise
      error(['load_data: Unknown product type ''' product '''.']);
  end

  % Restore the warning state
  warning(warnstate);

  function check_nargin(numargin, extra, product)
    errmsg = nargchk(3+extra, 3+extra, numargin);
    if length(errmsg) > 0
      errmsg = ['load_data [' product ']: ' errmsg];
      error(errmsg);
    end
  end

  function check_vars(request, known) % {{{
    % Find the intersection of the requested variables with the list of known
    % variables, including the default wildcard
    [inter,idxreq,idxknw] = intersect(request, {'*',known{:}} );
    % Then remove any known vars from the requested list
    request(idxreq) = [];
    % If there are any remaining variables being requested, then warn
    % the user.
    if length(request) > 0
      % Trick to turn the array of variables into a comma separated list in a
      % single string, ready for printing.
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

