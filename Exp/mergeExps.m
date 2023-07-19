function mergeExps(inFiles, outFile)

	for i = 1:numel(inFiles)
		f(i) = expread(inFiles{i});
		disp(['  Loading from exp file: ', inFiles{i}]);
		inPolygons(i) = polyshape(f(i).x, f(i).y);
	end
	outPolygon = union(inPolygons);

	% remove nan
	nanPos = ~isnan(sum(outPolygon.Vertices, 2));

	out = struct();
	out.density = 1;
	out.closed = 1;
	out.name = outFile;
	out.x = outPolygon.Vertices(nanPos,1);
	out.y = outPolygon.Vertices(nanPos,2);
	% close the exp
	if out.closed
		out.x(end+1) = out.x(1);
		out.y(end+1) = out.y(1);
	end

	out.nods = numel(out.x);

	disp(['  Save to exp file: ', outFile])
	expwrite(out, outFile);
end
