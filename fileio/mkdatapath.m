function path=mkdatapath()
% path=mkdatapath()
%
% Like datapath(), but also checks for existence of the output directory
% and creates the directory, if necessary.
%

  path = datapath();
  if ~exist(path, 'dir')
    system(['mkdir -p ' path]);
  end
end

