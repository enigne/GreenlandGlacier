function dataFL_all = projectSolutionsToFlowlines(md, flowlineList, icelevelset, time, Xdist, data)
	% project `data` along the flowlines, interpolate and extrapolate if the values are NaN
	% Xdist is the distance from ice front along the flowline, negative for upstream, positive for downstream 
	% iceleveset and data should have the same dimension, and same number of columns as time
	if size(data) ~= size(icelevelset)
		error('size of `data` and `icelevelset` is not the same!')
	end
	if numel(time) ~= size(icelevelset, 2)
		error('length of `time` is not the same as the number of columns of `icelevelset`!')
	end

	% get the dimensions
	nFlowline = numel(flowlineList);
	nTime = numel(time);
	nX = numel(Xdist);
	% init 
	dataFL_all = zeros(nFlowline, nTime, nX);
	% project to each flowline
	for i = 1: nFlowline
		disp(['==> Projecting data to flowline ', num2str(i)])
		% x-levelset
		icemaskFL = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,icelevelset,flowlineList{i}.x,flowlineList{i}.y);
		% y-data
		dataFL = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,data,flowlineList{i}.x,flowlineList{i}.y);
		% interpolate and extrapolate along each flowline
		for j = 1:nTime
			x = icemaskFL(:,j);
			y = dataFL(:,j);
			nanFlag = ((~isnan(y)));
			dataFL_all(i,j,:) = interp1(x(nanFlag), y(nanFlag), Xdist, 'nearest', 'extrap');
		end
	end
