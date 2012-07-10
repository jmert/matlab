function plotsize(handle, width, height, units)
%PLOTSIZE Set the plot window size.
%    plotsize(handle, width, height, units)
%
%INPUTS
%    handle  A graphics handle.
%    width   The width of the plot window.
%    height  The height of the plot window.
%    units   The unit system used in width and height. Accepts any unit
%            system which is compatible with the set() function.
%
%NOTES
%    1) width and height are mandatory arguments.
%    2) units is optional, and defaults to 'inches' if not set or empty.
%
%EXAMPLE
%    imagesc(map);
%    plotsize(gcf, 12, 9, 'centimeters');
%
%SEEALSO
%    doc figure_props

	if ~exist('handle', 'var')
		error('handle must be specified');
	end
	if ~exist('width', 'var')
		error('width must be specified');
	end
	if ~exist('height', 'var')
		error('width must be specified');
	end

	if ~exist('units', 'var')
		units = [];
	end
	if isempty(units)
		units = 'Inches';
	end
	
	% Save the old unit system
	oldunits = get(handle, 'Units');

	set(handle, 'Units', units);
	p = get(handle, 'Position');
	set(handle, 'Position', [p(1) p(2) width height]);

	% Restore the unit system
	set(handle, 'Units', oldunits);

end

