function files=glob(pattern)
% files = glob(pattern)
%
% List all files matching the glob pattern. If pattern is a directory name,
% then the contents of the directory are listed.
%
% EXAMPLES
%   glob('maps/1351/real_e_filtp3_weight3_gs_dp110{0,2}_jack?1.mat');
%   glob('input_maps/planck/planck_derivs_{nopix,bicepext}/*_cutbicepext.fits');
%
  if exist(pattern, 'dir')
    pattern = fullfile(pattern, '*');
  end
  files = glob_c(pattern);
end
