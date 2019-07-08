function i = maxind(varargin)
% i = maxind(varargin)
%
% Wrapper for
%   [~,i] = max(varargin{:});
% to allow calling inline with other expressions.

  [~,i] = max(varargin{:});
end
