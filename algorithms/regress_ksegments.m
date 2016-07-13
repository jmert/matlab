function reg=regress_ksegments(series,weights,k)
% reg=regress_ksegments(series,weights,k)
%
% Applies the Bellman k-segmentation regression across a weighted series.
%
% INPUTS
%   series       A row vector of data which is to be regressed.
%
%   weights      The weight of each data point. If not given or empty, then
%                the default choise will be equal weights for all data points
%                with weight 1/numel(series).
%
%   k            The number of segments to partition to.
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
%       y_reg = regress_ksegments(y, [], 10);
%
%   Otherwise if some weighting w is known for the data,
%
%       [y,w] = f(x);
%       y_reg = regress_ksegments(y, w, 10);
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
%   The regression is a dynamic programming implementation of Bellman's
%   k-segmentation algorithm as described by the recursion relation
%
%                /
%                |  e(1,i)                                 if     p == 1
%                |
%       E(p,i) = |  min_{1<=j<=i}( E(p-1,j-1) + e(j,i) )   if 1 < p <  i
%                |
%                |  0                                      if     p >= i
%                \
%
%
%   where e(j,i) is the error incurred by representing elements x_j...x_i
%   with a single line segment, and E(p-1,j-1) is the error of incurred by
%   representing x_1...x_(j-1) with the optimal (p-1)-segmentation. The
%   L2-norm squared distance away from the weighted mean of x_i...x_j defines
%   x(i,j).
%
%   Peak memory requirements scale as O(4n^2) for an array x_1...x_n.
%
% REFERENCES
%
%   [1] N. Haiminen, A. Gionis, & K. Laasonen. (2008) "Algorithms for
%       unimodal segmentation and applications to unimodality detection".
%       Knowledge and Information Systems, 14(1): 39--57.
%       (http://dx.doi.org/10.1007/s10115-006-0053-3)
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

  % Make sure the choice of k makes sense
  if k < 1 || k > numel(series)
    error('k must be in the range 1 to numel(series)')
  end

  N = numel(series);

  % Get pre-computed distances and means for single-segment spans over any
  % arbitrary subsequence series(i:j). The costs for these subsequences will
  % be used *many* times over, so a huge computational factor is saved by
  % just storing these ahead of time.
  [one_seg_dist,one_seg_mean] = prepare_ksegments(series, weights);

  % Keep a matrix of the total segmentation costs for any p-segmentation of
  % a subsequence series(1:n) where 1<=p<=k and 1<=n<=N. The extra column at
  % the beginning is an effective zero-th row which allows us to index to
  % the case that a (k-1)-segmentation is actually disfavored to the 
  % whole-segment average.
  k_seg_dist = zeros(k,N+1);
  % Also store a pointer structure which will allow reconstruction of the
  % regression which matches. (Without this information, we'd only have the
  % cost of the regression.)
  k_seg_path = nan(k,N);

  % Initialize the case k=1 directly from the pre-computed distances
  k_seg_dist(1,2:end) = one_seg_dist(1,:);

  % Any path with only a single segment has a right (non-inclusive) boundary
  % at the zeroth element.
  k_seg_path(1,:) = 0;
  % Then for p segments through p elements, the right boundary for the (p-1)
  % case must obviously be (p-1).
  k_seg_path(sub2ind(size(k_seg_path),1:k,1:k)) = (1:k) - 1;

  % Now go through all remaining subcases 1 < p <= k
  for p=2:k
    % Update the substructure as successively longer subsequences are
    % considered.
    for n=p:N
      % Enumerate the choices and pick the best one. Encodes the recursion
      % for even the case where j=1 by adding an extra boundary column on the
      % left side of k_seg_dist. The j-1 indexing is then correct without
      % subtracting by one since the real values need a plus one correction.
      choices = k_seg_dist(p-1,(1:n)) + one_seg_dist(1:n,n)';

      [bestval,bestidx] = min(choices);

      % Store the sub-problem solution. For the path, store where the (p-1)
      % case's right boundary is located.
      k_seg_path(p,n) = bestidx - 1;
      % Then remember to offset the distance information due to the boundary
      % (ghost) cells in the first column.
      k_seg_dist(p,n+1) = bestval;
    end
  end

  % Eventual complete regression
  reg = nan(size(series));

  % Now use the solution information to reconstruct the optimal regression.
  % Fill in each segment reg(i:j) in pieces, starting from the end where the
  % solution is known.
  rhs = numel(reg);
  for p=k:-1:1
    % Get the corresponding previous boundary
    lhs = k_seg_path(p,rhs);

    % The pair (lhs,rhs] is now a half-open interval, so set it appropriately
    reg(lhs+1:rhs) = one_seg_mean(lhs+1,rhs);

    % Update the right edge pointer
    rhs = lhs;
  end
end




function [dists,means]=prepare_ksegments(series,weights)
% [dists,means]=prepare_ksegments(series,weights)
%
% Pre-computes the mean-squared error and mean value for all possible
% contiguous subsets of series.
%
% INPUTS
%
%   series       A row vector of data values.
%
%   weights      The weight of each data point.
%
% RETURNS
%
%   dists        A square matrix with the upper triangle giving the mean-
%                squared distance of the data subset from its own mean.
%                The matrix is of the form:
%
%                    dists(i,j) = MSE(series(i:j))
%
%   means        As above with dists but gives the mean of the data:
%
%                    means(i,j) = mean(series(i:j))
%

  N = numel(series);

  % Allocate matrices
  wgts = diag(weights);
  wsum = diag(weights .* series);
  sqrs = diag(weights .* series.^2);

  % Set the lower part of the matrix to NaN as an extra layer of checks that
  % nothing wrong happens. If NaN's show up any point, then there's an
  % incorrect access into this matrix happening.
  dists = zeros(N)     + tril(nan(N,N),-1);
  means = diag(series) + tril(nan(N,N),-1);

  % Fill the upper triangle of dists and means by performing up-right
  % diagonal sweeps through the matrices.
  for delta=1:N
    for l=1:N-delta
      % l = left boundary
      % r = right boundary
      r = l + delta;

      % Incrementally update every partial sum
      wgts(l,r) = wgts(l,r-1) + wgts(r,r);
      wsum(l,r) = wsum(l,r-1) + wsum(r,r);
      sqrs(l,r) = sqrs(l,r-1) + sqrs(r,r);

      % Calculate the mean over the range
      means(l,r) = wsum(l,r) / wgts(l,r);
      % Then update the distance calculation. Normally this would have a term
      % of the form
      %   - wsum(l,r).^2 / wgts(l,r)
      % but one of the factors has already been calculated in the mean, so
      % just reuse that.
      dists(l,r) = sqrs(l,r) - means(l,r)*wsum(l,r);
    end
  end
end

