function i = minind(varargin)
% i = minind(varargin)
%
% Wrapper for
%   [~,i] = min(varargin{:});
% to allow calling inline with other expressions.

  [~,i] = min(varargin{:});
end

