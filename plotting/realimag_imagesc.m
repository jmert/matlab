function varargout=realimag_imagesc(varargin);

  if nargin == 1 || (nargin >= 1 && ~isreal(varargin{1}))
    xy = {};
    A = varargin{1};
    varargin = varargin(2:end);
  elseif nargin == 3 || (nargin >= 3 && ~isreal(varargin{3}))
    xy = varargin(1:2);
    A = varargin{3};
    varargin = varargin(4:end);
  else
    error('Could not interpret input');
  end

  rA = real(A);
  iA = imag(A);
  sz = size(A);

  ii = floor(sz(2)/2);
  jj = ii + 1;
  mA = [iA(:,1:ii), rA(:,jj:end)];
  [varargout{1:nargout}] = imagesc(xy{:}, mA, varargin{:});
end
