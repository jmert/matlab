function gentags=filter_existing(tags,product,varargin)
%gentags=filter_existing(tags,product,varargin)
%
%Checks whether the tags already have an associated data product on disk. If
%they do, the tag is removed from the returned list. The output tag list can
%then be used to process new data products without duplicating work.
%
%INPUTS
%  TAGS       List of tags to filter
%  PRODUCT    A string identifying the type of data product to check for.
%             See GET_DATA_PATH's "Data Products" section for more information.
%  VARARGIN   A position-dependent list of extra parameters which may be
%             required to perform the proper checks.
%             See GET_DATA_PATH's "Data products" section for more information.
%
%OUTPUTS
%  GENTAGS    The list of tags which are missing the corresponding data product
%
%EXAMPLES
%  newpairmaps = filter_existing(tags, 'pairmap', mapopt);
%  reduc_makepairmaps(newmaps, mapopt);
%

  % Generate the list of file names
  fnames = cellfun(@(x) get_data_path(x, product, varargin{:}), tags, ...
      'uniformoutput',false);
  % Then determine which ones do not exist
  mask = cellfun(@(x) ~exist(x,'file'), fnames);

  % Extract the tags which need to be generated. If none do, then just
  % return
  gentags = tags(mask);
end

