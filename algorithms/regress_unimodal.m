function reg=regress_unimodal(series,weights)
% reg=regress_unimodal(series,weights)
%
% Applies a unimodal regression across a weighted series.
%
% INPUTS
%   series       A row vector of data which is to be regressed.
%
%   weights      The weight of each data point. If not given or empty, then
%                the default choise will be equal weights for all data points
%                with weight 1/numel(series).
%
% RETURNS
%   reg          A row vector of the same length as series which has every
%                data point moved to be the regression of the input.
%
% EXAMPLE
%
%   Assume 1xN vector x that return values from some function f(x). For equal
%   weigting on all y(i),
%
%       y = f(x);
%       y_reg = regress_unimodal(y);
%
%   Otherwise if some weighting w is known for the data,
%
%       [y,w] = f(x);
%       y_reg = regress_unimodal(y, w);
%
%   Then plot to see how the distributions compare.
%
%       hold on
%       stairs(x, y, 'b');
%       stairs(x, y_reg, 'r');
%       hold off
%
% ALGORITHMIC DESCRIPTION
%
%   The unimodal regression algorithm implemented here is based on the
%   pseudocode provided in [1]. The basic idea is to perform two monotonic
%   regressions (one increasing and one decreasing) according to some metric
%   and minimize the total cost of both. The unimodal regression is then
%   the concatenation of the increasing portion up to the mode followed by
%   the decreasing portion.
%
%   Here the L2-norm has been chosen as the distance function because it
%   provides convenient mathematical properties that allow for an O(n)
%   runtime to be achieved. See [1] for more information on different choices
%   of cost function.
%
% REFERENCES
%
%   [1] Q. Stout. (2000) "Optimal algorithms for unimodal regression",
%       In: Wegman E, Martinez Y (eds) Computing science and statistics,
%       vol 32. Interface Foundation of North America, Fairfax, VA.
%       (http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.35.5749)
%

  % Make sure we have a row vector to work with
  if numel(series) == 1
    % Only a scalar value
    error('series must have length > 1')

  elseif size(series,1) > 1 && size(series,2) == 1
    % Got a column vector, so transpose
    series = series';

  elseif size(series,1) ~= 1
    % The input was a matrix, so we can't continue
    error('series must be a vector');
  end

  % Fill in weights with default value if not given.
  if ~exist('weights','var') || isempty(weights)
    weights = ones(size(series)) / numel(series);
  end

  % Ensure series and weights have the same size
  if ~all(size(series) == size(weights))
    error('series and weights must have the same shape')
  end

  % Perform the prefix scans twice. The first time does the monotonic
  % non-decreasing regression and the second effectively does the
  % non-increasing regression by working on the array in reverse.
  [distl,meanl,lptr] = regress_prefix_L2(series, weights);
  [distr,meanr,rptr] = regress_prefix_L2(series(end:-1:1), weights(end:-1:1));

  % The total cost function is simply the sum of the two increasing and
  % decreasing costs (of course over corresponding elements after re-reversing
  % distr).
  dist = distl + distr(end:-1:1);
  % The mode occurs where the cost is minimized
  [m,i] = min(dist);

  reg = zeros(size(series));
  
  % Reconstruct the required portions of the regression. The increasing
  % portion comes from elements 1:i.
  reg(1:i) = regress_isotonic(meanl(1:i), lptr(1:i));

  % The decreasing portion is needed for i:end but since the reconstruction
  % is reversed, we calculate the length of the segment as j.
  j = numel(series) - i;
  reg(end:-1:i+1) = regress_isotonic(meanr(1:j), rptr(1:j));
end



function reg=regress_isotonic(means,lptrs)
% reg=regress_isotonic(means,lptrs)
%
% Reconstruct a monotonically non-decreasing regression from given a set of
% prefix scan information.
%
% EXAMPLES
%
%   The inputs come from regress_prefix_L2 over a 1xN input x:
%
%       [distl,meanl,lptr] = regress_prefix_L2(x);
%
%   The full best-fit, monotonically non-decreasing sequence is then
%   reconstructed with
%
%       fullfit = regress_isotonic(meanl, lptr);
%
%   The information, though, is also sufficient to provide a regression over
%   any subset x(1:i) where 1<i<=N. The back tracking starts with the last
%   element in lptrs, so to do a regression over only the first half of x:
%
%       n2 = len(x) / 2;
%       halffit = regress_isotonic(meanl(1:n2), lptr(1:n2));
%

  reg = zeros(size(lptrs));

  % Backtrack through the records
  ii = numel(lptrs);
  while (ii > 1)
    reg(lptrs(ii):ii) = means(ii);
    ii = lptrs(ii) - 1;
  end
end




function [dists,means,lptrs]=regress_prefix_L2(series,weights)
% [dists,means,lptrs]=regress_unimodal(series,weights)
%
% Performs a prefix scan over the input series and returns information from
% which a monotonically non-decreasing sequence over all truncated lengths
% of the original series can be constructed.
%
% INPUTS
%   series       A row vector of data which is to be regressed.
%
%   weights      The weight of each data point.
%
% RETURNS
%   Note! As a prefix scan operation, the return values contain information
%   from which a variety of solutions can be reconstructed; in particular,
%   there is not a 1-to-1 correspondence between the contents of any element
%   of dists(i)/means(i)/lptrs(i) and series(i). To see an example of proper
%   use of the return values, see the regress_isotonic function.
%
%   dists        The costs of the regression. dists(i) is the L2^2 cost 
%                for regressing series(1:i).
%
%   means        For a particular i, means(i) is the weighted mean value for
%                the segment that contains series(i).
%
%   lptrs        The left edge of the line segment which contains series(i).
%

  % Skip input checks since this is a private function only callalbe by
  % the main regress_unimodal function. If this is split out any point, the
  % checks in regress_unimodal should probably be replicated here.

  N = numel(series);

  % Preallocate outputs and rolling sums.
  %
  % means needs a sentinal value at means(1), so for symmetry, have all
  % vectors of equal length. We'll truncate on return.
  dists = zeros(1, N+1);
  means = zeros(1, N+1);
  lptrs = zeros(1, N+1);

  sums = zeros(1,N+1);
  sqrs = zeros(1,N+1);
  wgts = zeros(1,N+1);

  % The partial sum, squared sum, and weight sums were initialized during
  % each loop invocation in the original paper. Boost outside the loop and
  % use vector operations instead.
  sums(2:end) = weights .* series;
  sqrs(2:end) = series .* sums(2:end);
  wgts(2:end) = weights;

  % Set the initial mean value to a sentinal
  means(1) = -Inf;

  % Now run over all elements
  for ii=2:N+1
    % Left boundary of the current segment is just this element initially
    lbound = ii;
    % The mean value of the currently constructed segment
    mval = series(ii-1); % ii-1 to account for sentinal boundary

    % While there is a violating condition, merge with the segment to the
    % left
    while (mval <= means(lbound-1))
      % Update the L2-norm components
      sums(ii) = sums(ii) + sums(lbound-1);
      sqrs(ii) = sqrs(ii) + sqrs(lbound-1);
      wgts(ii) = wgts(ii) + wgts(lbound-1);

      % Then do the merge by updating the left boundary pointer and
      % updating the mean of the segment
      lbound = lptrs(lbound-1);
      mval = sums(ii) / wgts(ii);
    end

    % With no violations left, store the mean, left boundary, and cost when
    % series(ii) is included.
    means(ii) = mval;
    lptrs(ii) = lbound;
    dists(ii) = dists(lbound-1) + (sqrs(ii) - sums(ii)*sums(ii)/wgts(ii));
  end

  % Now truncate the arrays that are returned to exclude the sentinal boundary
  dists = dists(2:end);
  means = means(2:end);
  % Subtract one from lptrs to fix up all the index pointers
  lptrs = lptrs(2:end) - 1;
end

