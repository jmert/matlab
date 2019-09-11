function tf = issymlink(fname)
% tf = issymlink(fname)
%
% Returns true if the given filename `fname` is a symlink, otherwise false.
%
% EXAMPLES
%   dirs = dir();
%   % annotate a bit like `ls -F`
%   for ii = 1:length(dirs)
%     suf = '';
%     if issymlink(dirs(ii).name)
%       suf = '@';
%     elseif dirs(ii).isdir
%       suf = filesep();
%     end
%     disp([dirs(ii).name suf]);
%   end

  tf = issymlink_c(fname);
end
