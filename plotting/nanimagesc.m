function varargout=nanimagesc(varargin)
% varargout=nanimagesc(varargin)
%
% Simple wrapper around imagesc which also sets alpha value such that NaN
% elements are transparent. See imagesc for all valid inputs.
%

  [tmp{1:max(1,nargout)}] = imagesc(varargin{:});
  im = tmp{1};
  set(im, 'AlphaData', ~isnan(get(im, 'CData')));
  [varargout{1:nargout}] = deal(tmp{1:nargout});
end

