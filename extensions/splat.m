function varargout=splat(F,varargin)
% [varargout]=splat(F,varargin)
%
% Calls the function F with the provided arguments. varargin is flattened, and
% if the only argument is a non-char array, the array elements are used as
% input instead. Useful for composing calls without needing an intermediate
% temporary storage variable.
%
% EXAMPLE
%   nums = arrayfunc(@(n) sprintf('%e', n), rand(100,1)*1e-4);
%   parts = regexp(nums, '([0-9.-]+)e[-+]([0-9]+)', 'tokens');
%
%   fracs = splat(@vertcat, cellfunc(@(c) c{1}{1}, parts));
%   pows  = splat(@vertcat, cellfunc(@(c) c{1}{2}, parts));
%
%   % Without splat, the direct translation is:
%   %   tmp = cellfunc(@(c) c{1}{1}, parts);
%   %   fracs = vertcat(tmp{:});
%   %   tmp = cellfunc(@(c) c{1}{2}, parts);
%   %   pows  = vertcat(tmp{:});
%

  args = flatten(varargin);
  if numel(args) == 1 && ~ischar(args{1})
    args = mat2cell(cvec(args{1}), ones(numel(args{1}),1));
  end
  [varargout{1:nargout}] = feval(F, args{:});
end

