% Project the Transient solutions and time dependent variables to the 0-levelset isoline
%	
% Last modified: 2022-06-19

function projectAblationRateToIsoline(varargin)
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
	%GET CALFIN model{{{
	mdCALFINFolder = getfieldvalue(options, 'CALFIN model', '');
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
	%GET velocity threshold: 4000{{{
	velThreshold = getfieldvalue(options, 'velocity threshold', 4000);
	% }}}
	%GET choose branch: 0 - no, 1 - northern, 2 - center/southern: {{{
	chooseBranch = getfieldvalue(options, 'choose branch', 0);
	% }}}
	%GET branch threshold: 0{{{
	branchThreshold = getfieldvalue(options, 'branch threshold', 0);
	% }}}
	%GET dataname: cmRates{{{
	dataname = getfieldvalue(options, 'dataname', 'cmRates');
	% }}}

	% load model {{{
	org=organizer('repository', [projPath, '/Models/', mdCALFINFolder], 'prefix', ['Model_' glacier '_'], 'steps', 0);
	disp(['    Loading model from ', mdCALFINFolder]);
	md = loadmodel(org, stepName);
	% load transient data
	time = cell2mat({md.results.TransientSolution(:).time});
	Nt = length(time); % time steps of the mask
	vel = cell2mat({md.results.TransientSolution(:).Vel});
	sigmaVM = cell2mat({md.results.TransientSolution(:).SigmaVM});
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
		if strcmp(dataname, 'cmRates')
			aRate = aratedata.cmRates;
		elseif strcmp(dataname, 'sigmaMax')
			aRate = aratedata.sigmaMax;
		else 
			error('unknown dataname')
		end
		%% process data {{{
		zeroLS = '';
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
			zeroLS(i).HC = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,md.results.TransientSolution(i).Thickness,levelx,levely,'default',NaN);
			zeroLS(i).BedC = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,md.results.TransientSolution(i).Base,levelx,levely,'default',NaN);
			zeroLS(i).aRateC = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,aRate(:,i),levelx,levely,'default',NaN);
			zeroLS(i).velC = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,vel(:,i),levelx,levely,'default',NaN);
			zeroLS(i).sigmaC = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,sigmaVM(:,i),levelx,levely,'default',NaN);
		end
		%}}}
		% rearrange the iosline data into a matrix{{{
		disp(['    reshape isoline data to a matrix'])
		Ncont = cellfun(@length, {zeroLS(:).aRateC});
		dist = cellfun(@(x) x(end), {zeroLS(:).dist});
		% find the max length of the isoline
		maxN = max(Ncont);
		maxDist = max(dist);
		xDist = linspace(0, maxDist, maxN);
		%padding = [ceil((maxN-Ncont)/2)+1; maxN-floor((maxN-Ncont)/2)]; % align in the center
		%padding = [maxN-Ncont+1;ones(1,Ndata)*maxN];  % to the end
		%padding = [ones(1,Ndata); Ncont];  % start from the beginning

		aRateC = nan(maxN, Nt);
		BedC = nan(maxN, Nt);
		HC = nan(maxN, Nt);
		VelC = nan(maxN, Nt);
		SigmaC = nan(maxN, Nt);
		XC = nan(maxN, Nt);
		YC = nan(maxN, Nt);
		times = repmat([1:Nt], maxN, 1);
		% project to the new xDist grid
		for i = 1:Nt
			aRateC(:,i) = interp1(0.5*(maxDist-zeroLS(i).dist(end)) + zeroLS(i).dist, zeroLS(i).aRateC, xDist, 'linear');
			BedC(:,i) = interp1(0.5*(maxDist-zeroLS(i).dist(end)) + zeroLS(i).dist, zeroLS(i).BedC, xDist, 'linear');
			HC(:,i) = interp1(0.5*(maxDist-zeroLS(i).dist(end)) + zeroLS(i).dist, zeroLS(i).HC, xDist, 'linear');
			VelC(:,i) = interp1(0.5*(maxDist-zeroLS(i).dist(end)) + zeroLS(i).dist, zeroLS(i).velC, xDist, 'linear');
			SigmaC(:,i) = interp1(0.5*(maxDist-zeroLS(i).dist(end)) + zeroLS(i).dist, zeroLS(i).sigmaC, xDist, 'linear');
			XC(:,i) = interp1(0.5*(maxDist-zeroLS(i).dist(end)) + zeroLS(i).dist, zeroLS(i).contours.x, xDist, 'linear');
			YC(:,i) = interp1(0.5*(maxDist-zeroLS(i).dist(end)) + zeroLS(i).dist, zeroLS(i).contours.y, xDist, 'linear');
		end
		%}}}
		% cleanup {{{
		% some threashold
		nanflag = isnan(BedC);
		nanflag = nanflag | (BedC > -0);
		nanflag = nanflag | (aRateC < 0);
		nanflag = nanflag | (VelC < velThreshold);
		if (chooseBranch == 1) % northern
			nanflag(xDist < branchThreshold,:) = 1;
		elseif (chooseBranch == 2) % center or southern
			nanflag(xDist > branchThreshold,:) = 1;
		end

		aRateC(nanflag) = nan;
		BedC(nanflag) = nan;
		HC(nanflag) = nan;
		timeC(nanflag) = nan;
		maxArateC = max(aRateC);
		meanArateC = mean(aRateC, 'omitnan');
		% if maxArateC has nan, change it to 0
		maxArateC(isnan(maxArateC)) = 0;
		meanArateC(isnan(meanArateC)) = 0;
		%}}}
		%% save {{{
		if saveFlag
			saveFilename = [projPath, resultsFolder, sfilename, num2str(timeWindows(tw))];
			if strcmp(dataname, 'cmRates')
				disp(['    Saving aRateC to ', saveFilename]);
				save([saveFilename, '.mat'], 'time', 'xDist', 'timeC', 'HC', 'BedC', 'aRateC', 'maxArateC', 'meanArateC', 'VelC', 'SigmaC', 'XC', 'YC');
			elseif strcmp(dataname, 'sigmaMax')
				sigmaMaxC = aRateC;
				maxSigmaMaxC = maxArateC;
				meanSigmaMaxC = meanArateC;
				disp(['    Saving sigmaMaxC to ', saveFilename]);
				save([saveFilename, '.mat'], 'time', 'xDist', 'timeC', 'HC', 'BedC', 'sigmaMaxC', 'maxSigmaMaxC', 'meanSigmaMaxC', 'VelC', 'SigmaC', 'XC', 'YC');
			else 
				error('unknown dataname')
			end
		end
		%}}}
	end %}}}
