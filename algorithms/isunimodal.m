function [TF,varargout]=isunimodal(series,weights,threshold,model)
% TF = isunimodal(series,weights,threshold,model)
% [TF,errparam] = isunimodal(series,weights,threshold,model)
%
% Classifies whether a series is unimodal or not by comparing the mean-squared
% errors of a unimodal regression versus another regression model. The
% mean-square error is defined as
%
%     MSE(y, y_fit) = 1/numel(y) * sum((y - y_fit).^2)
%
% The unimodality tests chosen are based on the work in [1]. See the
% paper for more information.
%
% INPUTS
%
%   series       A row vector of data which is to be tested.
%
%   weights      The weight of each data point. If not given or empty, then
%                the default choise will be equal weights for all data points
%                with weight 1/numel(series).
%
%   threshold    Expected to be a two-element array giving the upper and
%                lower acceptable bounds for the error parameter. A fit is
%                deemed unimodal iff
%
%                    threshold(1) < errparam < threshold(2)
%
%                otherwise the distribution is determined to be multimodal.
%                Defaults to [0 10];
%
%   model        The second regression model to use as a baseline for
%                comparing how well a unimodel regression fit the data. The
%                valid choices are:
%
%                  'none' | [] (Default)
%                      No additional regression is performed, and error
%                      parameter is determined from the raw data.
%
%                  'ksegment' | 'ksegmentation'
%                      The Bellman k-segementation regression is used on the
%                      data. The number of segments k is chosen to be the
%                      number of segments that the unimodel regression
%                      generated.
%
%                      Note that this has a runtime-complexity of O(k*n^2)
%                      and can very quickly become computationally
%                      infeasible.
%
%                  function_handle
%                      If given a function handle, then the function is
%                      executed as in
%
%                          model_fit = model(series, weights);
%
%                      Therefore the referrent function should accept two
%                      arguments which are the data series and associated
%                      weights and return a regression which has the same
%                      size has series.
%
% RETURNS
%   TF           A logical stating whether the input series is unimodel
%                as determined by the choice of reference model and a
%                model-specific threshold.
%
%   errparam     The error parameter which was calculated.
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

  if ~exist('weights','var') || isempty(weights)
    weights = ones(size(series)) / numel(series);
  end
  if ~exist('model','var') || isempty(model)
    model = 'none';
  end

  % Ensure series and weights have the same size
  if ~all(size(series) == size(weights))
    error('series and weights must have the same shape')
  end

  if ~exist('threshold') || isempty(threshold)
    threshold = [0 10];
  end

  % Perform the unimodal regression and calculate the mean-squared error.
  uni_reg = regress_unimodal(series, weights);


  % Convert string model choices to a relevant model function
  if ischar(model)
    switch lower(model)
      case 'none'
        % Just pass through the original data
        model = @(series, weights) series;

      case {'ksegments','ksegmentation'}
        % Find how many segments were used in the unimodal regression
        numk = sum(diff(uni_reg) ~= 0) + 1;
        % Effectively bind the regress_ksegments function call with only k given
        model = @(series,weights) regress_ksegments(series, weights, numk);

      otherwise
        error('Unrecognized model type. Consider using a function handle.')
    end
  end

  % Have the model run its regression on the data
  if ~isa(model, 'function_handle')
    error('Expected model to be a function handle (or valid string name; see documentation)');
  end
  model_reg = model(series, weights);

  % Calculate the unimodality parameters and make a determination
  crit = sum((uni_reg - model_reg).^2) / numel(series);
  TF = (threshold(1) < crit && crit < threshold(2));

  % Handle the case of optional outputs
  if (nargout >= 2)
    varargout{1} = crit;
  end
end
