% Project the Transient solutions and time dependent variables to the 0-levelset isoline
%	
% Last modified: 2023-04-27

function projectAblationRate(varargin)
	%Check inputs {{{
	%recover options
	options=pairoptions(varargin{:});
	% }}}
	%GET glacier: Can NOT be empty{{{
	glacier = getfieldvalue(options,'glacier', '');
	if isempty(glacier)
		error('glacier can not be empty')
	end
	% }}}
	%GET path (of the workspace) {{{
	workingPath = getfieldvalue(options,'path','/totten_1/chenggong/');
	projPath = [workingPath, glacier, '/'];
	% }}}
	%GET results folder : './PostProcessing/Results/'{{{
	resultsFolder = getfieldvalue(options,'results folder','./PostProcessing/Results/');
	% }}}
	%GET step name{{{
	stepName = getfieldvalue(options, 'step name', 'Transient');
	% }}}
	%GET ref front model{{{
	mdRefFrontsFolder = getfieldvalue(options, 'ref front model', '');
	% }}}
	%GET data filename: Arates_Obs{{{
	datafilename = getfieldvalue(options, 'data filename', 'Arates_Obs');
	% }}}
	%GET save filename: Arates_Obs_Isoline_aver{{{
	sfilename = getfieldvalue(options, 'save filename', 'Arates_Obs_Isoline_aver');
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}
	%GET time windows: [0, 12, 30, 60, 90]{{{
	timeWindows= getfieldvalue(options, 'time windows', [0, 12, 30, 60, 90]);
	% }}}
	%GET flowline contour: flowlineContour{{{
	flowlineContourExp = getfieldvalue(options, 'flowline contour', 'flowlineContour');
	% }}}
	%GET velocity threshold: 4000{{{
	velThreshold = getfieldvalue(options, 'velocity threshold', 4000);
	% }}}
	%GET choose branch: 0 - no, 1 - northern, 2 - center/southern: {{{
	chooseBranch = getfieldvalue(options, 'choose branch', 0);
	% }}}
	%GET branch threshold: 0{{{
	branchThreshold = getfieldvalue(options, 'branch threshold', 0);
	% }}}

	% load model {{{
	org=organizer('repository', [projPath, '/Models/', mdRefFrontsFolder], 'prefix', ['Model_' glacier '_'], 'steps', 0);
	disp(['    Loading model from ', mdRefFrontsFolder]);
	md = loadmodel(org, stepName);
	% load transient data
	time = cell2mat({md.results.TransientSolution(:).time});
	Nt = length(time); % time steps of the mask
	vel = cell2mat({md.results.TransientSolution(:).Vel});
	sigmaVM = cell2mat({md.results.TransientSolution(:).SigmaVM});

	% compute sidewall distance using levelset function
	sidewall_levelset = zeros(md.mesh.numberofvertices,1);
	pos = (md.geometry.bed>0); sidewall_levelset(pos) = -1;
	pos = (md.geometry.bed<0); sidewall_levelset(pos) = 1;
	sidewall_levelset = reinitializelevelset(md, sidewall_levelset);

	% bed slope
	disp('    Computing bed slopes ')
	abed = averaging(md,md.geometry.bed, 20); % maybe executing 20 L2 projection is ok
	[bsx, bsy] = computeGrad(md.mesh.elements, md.mesh.x, md.mesh.y, abed); % compute the gradient

	% load C-flowline contour
	expfile = [projPath, '/PostProcessing/Results/', flowlineContourExp, '.exp'];
	disp(['    Load flowline contour from ', expfile])
	flowlineLevelset = ExpToLevelSet(md.mesh.x, md.mesh.y, expfile);

	% strain rate
	strainrateFlag = isfield(md.results.TransientSolution, 'StrainRateparallel');
	if strainrateFlag
		disp('    Loading strain rate solutions'); 
		StrainRateparallel = cell2mat({md.results.TransientSolution(:).StrainRateparallel});
		StrainRateperpendicular = cell2mat({md.results.TransientSolution(:).StrainRateperpendicular});
	end
	disp('    Loading model done!'); %}}}
	% process each time window averaged data{{{
	for tw = 1:length(timeWindows)
		if timeWindows(tw) > 0
			aratedatafile = [projPath, resultsFolder, datafilename, '_aver', num2str(timeWindows(tw))];
		else
			aratedatafile = [projPath, resultsFolder, datafilename];
		end
		disp(['    Loading the frontal ablation rate from ', aratedatafile]);
		aratedata = load([aratedatafile, '.mat']);
		aRtime = aratedata.time;
		aRate = aratedata.cmRates;
		%% process data {{{
		zeroLS = struct([]);

		disp('    Projecting the ablation rate to isoline')
		for i = 1:Nt
			allcontours=isoline(md, md.results.TransientSolution(i).MaskIceLevelset,'value',0);
			[num pos] = max(cellfun(@numel,{allcontours(:).x}));
			% selecting longest one only
			contours = allcontours(pos);
			levelx = contours.x;
			levely = contours.y;
			% check if need to flip
			if levely(1) > levely(end)
				levelx = flipud(levelx);
				levely = flipud(levely);
				contours.x = levelx;
				contours.y = levely;
				contours.z = flipud(contours.z);
			end

			% save contours and data in the same struct
			zeroLS(i).contours = contours;
			zeroLS(i).dist = cumsum([0;sqrt(diff(zeroLS(i).contours.x).^2 + diff(zeroLS(i).contours.y).^2)])/1e3;
			% project to isoline
			zeroLS(i).HC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,md.results.TransientSolution(i).Thickness,levelx,levely,NaN);
			zeroLS(i).BedC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,md.geometry.bed,levelx,levely,NaN);
			zeroLS(i).bxC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,bsx,levelx,levely,NaN);
			zeroLS(i).byC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,bsy,levelx,levely,NaN);
			zeroLS(i).aRateC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,aRate(:,i),levelx,levely,NaN);
			zeroLS(i).velC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,vel(:,i),levelx,levely,NaN);
			zeroLS(i).sigmaC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,sigmaVM(:,i),levelx,levely,NaN);
			zeroLS(i).sidewallDistC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,sidewall_levelset,levelx,levely,NaN);
			zeroLS(i).distToFlowlineC = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,flowlineLevelset,levelx,levely,NaN);
			if strainrateFlag
				zeroLS(i).StrainRateparallel = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,StrainRateparallel(:,i),levelx,levely,NaN);
				zeroLS(i).StrainRateperpendicular = InterpFromMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,StrainRateperpendicular(:,i),levelx,levely,NaN);
			end
		end
		%}}}
		% rearrange the iosline data into a matrix{{{
		disp(['    reshape isoline data to a matrix'])

		% find the maximal, both positive and negative, distToFlowlineC
		dist_min = min(cellfun(@min, {zeroLS(:).distToFlowlineC}));
		dist_max = max(cellfun(@max, {zeroLS(:).distToFlowlineC}));
		% max number of points
		Ncont = cellfun(@length, {zeroLS(:).aRateC});
		maxN = max(Ncont);
		% find the max length of the isoline
		xDist = linspace(dist_min, dist_max, maxN);

		aRateC = nan(maxN, Nt);
		BedC = nan(maxN, Nt);
		bxC = nan(maxN, Nt);
		byC = nan(maxN, Nt);
		HC = nan(maxN, Nt);
		VelC = nan(maxN, Nt);
		SigmaC = nan(maxN, Nt);
		sidewallDistC = nan(maxN, Nt);
		StrainRateparallelC = nan(maxN, Nt);
		StrainRateperpendicularC = nan(maxN, Nt);
		XC = nan(maxN, Nt);
		YC = nan(maxN, Nt);
		times = repmat([1:Nt], maxN, 1);
		% project to the new xDist grid
		for i = 1:Nt
			aRateC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).aRateC, xDist, 'linear');
			BedC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).BedC, xDist, 'linear');
			bxC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).bxC, xDist, 'linear');
			byC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).byC, xDist, 'linear');
			HC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).HC, xDist, 'linear');
			VelC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).velC, xDist, 'linear');
			SigmaC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).sigmaC, xDist, 'linear');
			sidewallDistC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).sidewallDistC, xDist, 'linear');
			if strainrateFlag
				StrainRateparallelC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).StrainRateparallel, xDist, 'linear');
				StrainRateperpendicularC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).StrainRateperpendicular, xDist, 'linear');
			end
			XC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).contours.x, xDist, 'linear');
			YC(:,i) = interp1(zeroLS(i).distToFlowlineC, zeroLS(i).contours.y, xDist, 'linear');
		end
		%}}}
		% cleanup {{{
		% some threashold
		nanflag = isnan(BedC);
		nanflag = nanflag | (BedC > -0);
		nanflag = nanflag | (aRateC < 0);
%		nanflag = nanflag | (VelC < velThreshold);
		if (chooseBranch == 1) % northern
			nanflag(xDist < branchThreshold,:) = 1;
		elseif (chooseBranch == 2) % center or southern
			nanflag(xDist > branchThreshold,:) = 1;
		end

		aRateC(nanflag) = nan;
		BedC(nanflag) = nan;
		bxC(nanflag) = nan;
		byC(nanflag) = nan;
		HC(nanflag) = nan;
		maxArateC = max(aRateC);
		meanArateC = mean(aRateC, 'omitnan');
		% if maxArateC has nan, change it to 0
		maxArateC(isnan(maxArateC)) = 0;
		meanArateC(isnan(meanArateC)) = 0;
		%}}}
		%% save {{{
		if saveFlag
			saveFilename = [projPath, resultsFolder, sfilename, num2str(timeWindows(tw))];
			disp(['    Saving aRateC to ', saveFilename]);
			save([saveFilename, '.mat'],	'time', 'xDist', 'HC', 'BedC', 'bxC', 'byC', 'aRateC', ...
													'maxArateC', 'meanArateC', 'VelC', 'SigmaC', 'sidewallDistC',...
													'XC', 'YC', 'StrainRateparallelC', 'StrainRateperpendicularC');
		end
		%}}}
	end %}}}
