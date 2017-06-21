function R=take(N,F,varargin)
% R=take(N,F,varargin)
%
% Returns the N-th output of the call to function F with arguments
% varargin.
%
% EXAMPLE
%   indx = take(2, @ismember, [-1,1], -10:10);
%
%   X = rand(20,1);
%   X(take(2, @max, X)) = Inf
%

  dum = cell(N-1,1);
  [dum{:},R] = F(varargin{:});
end
