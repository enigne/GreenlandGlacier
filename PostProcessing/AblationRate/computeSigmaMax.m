% To compute sigma_max using model velocity and sigmaVM
%
% Last modified: 2022-08-12

function computeSigmaMax(varargin)
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
	%GET vdata source{{{
	vdataSource = getfieldvalue(options, 'vdata source', 'Model');
	% }}}
	%GET vdata filename: timeSeries_Obs_onmesh_extrap{{{
	vfilename = getfieldvalue(options, 'vdata filename', 'timeSeries_Obs_onmesh_extrap');
	vdatafile = [projPath, resultsFolder, vfilename, '.mat'];
	% }}}
	%GET save filename: Arates_Obs{{{
	sfilename = getfieldvalue(options, 'save filename', 'SigmaMax');
	saveFilename = [projPath, resultsFolder, sfilename,'_', vdataSource '.mat'];
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}

	%% load {{{
	% load model with obs constraint front
	org=organizer('repository', [projPath, '/Models/', mdCALFINFolder], 'prefix', ['Model_' glacier '_'], 'steps', [0]);
	disp(['    Loading from ', mdCALFINFolder]);
	md = loadmodel(org, stepName);
	% load vel, sigmaVM, and melting rate parameterization
	disp(['    Loading model velocity from ', mdCALFINFolder]);
	vx = cell2mat({md.results.TransientSolution(:).Vx});
	vy = cell2mat({md.results.TransientSolution(:).Vy});
	vel = sqrt(vx.^2+vy.^2);
	disp(['    Loading sigmaVM, meltingrate and icemask  from ', mdCALFINFolder]);
	sigmaVM = cell2mat({md.results.TransientSolution(:).SigmaVM});
	mRate = cell2mat({md.results.TransientSolution(:).CalvingMeltingrate});
	icemask = cell2mat({md.results.TransientSolution(:).MaskIceLevelset});
	%}}}
	% data processing{{{
	% time
	dt = md.timestepping.time_step;
	time = cell2mat({md.results.TransientSolution(:).time});
	Nt = length(time);
	% prepare levelset and gradients
	numNodes = md.mesh.numberofvertices;
	%% fix the index shift in time stepping by setting phi(0)=spclevelset
	CFLevelset = [md.levelset.spclevelset(1:end-1,1), icemask];
	%% Compute dphi/dt
	dCFdt = (CFLevelset(:, 2:end) - CFLevelset(:, 1:end-1)) ./ dt;
	% ISSM uses implicit Euler for time stepping
	disp('    Computing the gradient of levelset function')
	[gradx, grady]=computeGrad(md.mesh.elements, md.mesh.x, md.mesh.y, CFLevelset(:,2:end));
	ndphi = sqrt(gradx.^2 + grady.^2);
	%% compute sigma_max
	sigmaMax = (vel.*sigmaVM) ./  ((dCFdt+vx.*gradx+vy.*grady)./ndphi - mRate);
	%}}}
	%% save {{{
	if saveFlag
		disp(['    Saving to ', saveFilename]);
		save([saveFilename], 'sigmaMax', 'time');
	end
	%}}}
