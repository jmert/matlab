function fname=get_data_path(tag, product, varargin)
%fname=get_data_path(tag, product, varargin)
%
%Get the path to various products in the pipeline based on tag name and other
%auxiliary information. Simplifies calls to Matlab's LOAD procedure.
%
%INPUTS
%    TAG        A tag string identifying the data to be loaded.
%    PRODUCT    One of the data products which are saved by the pipeline. A
%               complete list of valid data products are listed below in the
%               DATA PRODUCTS section.
%    VARARGIN   A position-dependent list of extra parameters which may be
%               necessary depending on the product files to be loaded. See
%               the DATA PRODUCTS section below for a complete description.
%
%OUTPUTS
%    FNAME      The file path for the requested data product.
%
%EXAMPLES
%    calpath = get_data_path('20100424E04_dk068', 'calval');
%    cals = load(calpath,'en','lc');
%      - or -
%    mappath = get_data_path([], 'map', coaddopt);
%    mapdat = load(mappath);
%    imagesc(mapdat.map.T);
%
%DATA PRODUCTS
%  A specific data product's path is returned by passing an appropriate name to
%  PRODUCT. Depending on the product, some extra information may be required to
%  build the path: this data is passed as position-dependent parameters
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
%  for the corresponding data product.
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

  % Get the initial number of input arguments
  numargin = nargin;

  switch product
    % The general structure of each case should be
    %   1. Verify number of extra parameters passed in
    %   2. Build a path to the file

    case 'calval' % {{{
      check_nargin(numargin, 0, 'calval');
      fname = ['data/real/' tag '_calval.mat'];
    % }}}
    case 'map' % {{{
      check_nargin(numargin, 1, 'map');

      % We require at least a serial number to exist within the coaddopt struct
      % since it is always a requirement
      coaddopt = varargin{1};
      if ~isstruct(coaddopt)
        error('get_data_path [map]: ''map'' expects a coaddopt struct');
      end
      if ~isfield(coaddopt,'sernum')
        error(['get_data_path [map]: Serial number (coaddopt.sernum) '...
             'must be given.']);
      end
      % Then use the get_default_coaddopt function to combine the given
      % structure with the required structure members.
      coaddopt = get_default_coaddopt(coaddopt);

      % If there is more than one jacktype at this stage, we also must bail
      % since we don't know which one we should load.
      if length(coaddopt.jacktype) > 1
        error(['get_data_path [map]: Only one jackknife type '...
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
      fname = sprintf('maps/%s/%s_%s_%s_jack%d%s.mat',...
            coaddopt.sernum(1:4),coaddopt.sernum(5:end),...
            coaddopt.daughter,fileext,...
            coaddopt.jacktype,coaddtype);
    % }}}
    case 'tod' % {{{
      check_nargin(numargin, 0, 'tod');
      fname = ['data/real/' tag '_tod.mat'];
    % }}}
    otherwise
      error(['get_data_path: Unknown product type ''' product '''.']);
  end

  function check_nargin(numargin, extra, product)
    errmsg = nargchk(2+extra, 2+extra, numargin);
    if length(errmsg) > 0
      errmsg = ['get_data_path [' product ']: ' errmsg];
      error(errmsg);
    end
  end
end

