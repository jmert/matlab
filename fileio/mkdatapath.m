function path=mkdatapath()
% path=mkdatapath()
%
% Like datapath(), but also checks for existence of the output directory
% and creates the directory, if necessary.
%

  path = mkdir_p(datapath());
end

