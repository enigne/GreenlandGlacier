function extractTransientFromMd(md, projPath, folder, dataName, flowlineList, saveflag, vel_onmesh, TStart, TEnd)

	%% extract time dependent solutions {{{
	% output 
	disp(['==== Start to process on ', folder]);
	name = dataName;
	transientSolutions = extractTransientSolutions(md);
	disp(['======> Finish data extraction ', folder]);
	% Prepare for saving
	time = transientSolutions.time;
	vel = transientSolutions.vel;
	ice_levelset = transientSolutions.ice_levelset;
	icevolume = transientSolutions.volume;
	% mean velocity
	vel(ice_levelset>0) = nan;
	meanVel = mean(vel, 'omitnan');

	% calving and melting rates at the flowlines
	disp(['======> Analyzing calving front ']);
	flowlines = flowlineList;
	for j = 1:length(flowlineList)
		[flowlines{j}, icemaskFL] = analyzeCalvingFront(md, flowlineList{j}, transientSolutions);
	end
	disp(['======> Analyzing calving front complete ']);
	% mean SMB
	if (isfield(transientSolutions, 'smb'))
		[meanSMB, sumSMB, areas] = integrateOverDomain(md, transientSolutions.smb);
	else
		meanSMB = 0;
	end

	% velocities, saved in a seperate file, they are very large
	vx = transientSolutions.vx;
	vy = transientSolutions.vy;
	vx(ice_levelset>0) = nan;
	vy(ice_levelset>0) = nan;

	% project the numerical solutions onto each of the observation     
	vx_aver = zeros(size(vel_onmesh));
	vy_aver = zeros(size(vel_onmesh));
	N = length(TStart);

	disp(['======> Projecting velocity solutions on the mesh of obs ']);
	for i = 1:N
		vx_aver(:,i) = averageOverTime(vx, time, TStart(i), TEnd(i));
		vy_aver(:,i) = averageOverTime(vy, time, TStart(i), TEnd(i));
	end

	disp(['======> Projecting vel along the flowlines ']);
	Xdist = [-100:5:-30, -29:1:-5,linspace(-5,1,floor(5e3/50))]*1e3;
	velFL_all = projectSolutionsToFlowlines(md, flowlineList, ice_levelset, time, Xdist, vel);
	velFL = squeeze(mean(velFL_all,1));

	% save data
	if saveflag
		savePath = [projPath, 'Models/', folder, '/'];
		disp(['======> Saving to ', savePath]);
		save([savePath, 'velSolutions', '.mat'], 'name',...
			'time', 'vx', 'vy', 'ice_levelset');

		save([savePath, 'transientSolutions', '.mat'], 'name', ...
			'time', 'icevolume', 'meanSMB', 'meanVel', 'flowlines', 'Xdist', 'velFL');

		save([savePath, 'compareToObs.mat'], 'vx_aver', 'vy_aver', 'dataName');

		disp(['======> Saving complete ']);
	end
	%}}}
