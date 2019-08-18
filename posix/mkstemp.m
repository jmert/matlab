function [tempfile,fd] = mkstemp(template)
% [tempfile,fd] = mkstemp(template)
%
% Generates a temp file from the given template.  Note that POSIX generates the
% file, so the temporary file must be removed by the caller when no longer
% needed.
%
% EXAMPLES
%   outfile = fullfile('data', 'path', 'filename.mat');
%   tempfile = mkstemp(outfile);
%   save(tempfile, '-v7.3', '-struct', 'datastruct');
%   movefile(tempfile, outfile);
%
  [dname,fname,fext] = fileparts(template);
  if ~strncmp(fliplr(fname), 'XXXXXX', 6)
    fname = [fname 'XXXXXX'];
  end
  template = fullfile(dname, [fname fext]);
  tempfile = mkstemp_c(template);
end
