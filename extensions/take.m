function R=take(N,F,varargin)
% R=take(N,F,varargin)
% R=take(N,Nmax,F,varargin)
%
% Returns the N-th output(s) of the call to function F with arguments
% varargin. In the second form, Nmax outputs are collected unconditionally,
% with only the N-th returned.
%
% EXAMPLE
%   indx = take(2, @ismember, [-1,1], -10:10);
%
%   X = rand(20, 1);
%   X(take(2, @max, X)) = Inf
%
%   % The second form with Nmax is required when the function behavior changes
%   % depending on the number of outputs. For example, compare:
%
%   X = rand(4, 4);
%   take(1, @svd, X);       % Returns vector, diagonal of S
%   take(1, 3, @svd, X);    % Returns U matrix
%

  isfn = @(f) isa(f, 'function_handle');

  if ~isfn(F) && length(varargin) >= 1 && isfn(varargin{1})
    Nmax = F;
    F = varargin{1};
    varargin = varargin(2:end);
  else
    Nmax = max(N);
  end

  out = cell(1, Nmax);
  [out{:}] = feval(F, varargin{:});
  if numel(N) > 1
    R = out(N);
  else
    R = out{N};
  end
end
