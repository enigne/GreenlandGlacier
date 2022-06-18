% To compute ablation rate from the observed calving front position using the given velocity data
%
% Last modified: 2022-06-18

function computeAblationRate(varargin)
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
	%GET vdata filename: timeSeries_Obs_onmesh{{{
	vfilename = getfieldvalue(options, 'vdata filename', 'timeSeries_Obs_onmesh_extrap');
	vdatafile = [projPath, resultsFolder, vfilename, '.mat'];
	% }}}
	%GET save filename: timeSeries_Obs_onmesh_extrap{{{
	sfilename = getfieldvalue(options, 'save filename', 'Arates_Obs');
	saveFilename = [projPath, resultsFolder, sfilename, '.mat'];
	% }}}
	%GET isSave: 1{{{
	saveFlag = getfieldvalue(options, 'isSave', 1);
	% }}}

	%% load {{{
	% load model with obs constraint front
	org=organizer('repository', [projPath, '/Models/', mdCALFINFolder], 'prefix', ['Model_' glacier '_'], 'steps', [0]);
	disp(['    Loading from ', mdCALFINFolder]);
	md = loadmodel(org, stepName);
	% load obs vel 
	disp(['    Loading obs velocity from ', vdatafile]);
	Vdata = load(vdatafile);
	%}}}
	% data processing{{{
	icemask = cell2mat({md.results.TransientSolution(:).MaskIceLevelset});
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
	denominator = sqrt(gradx.^2 + grady.^2);
	%% compute melting rate
	cmRates = 1./denominator.*(dCFdt+Vdata.vx_obs.*gradx+Vdata.vy_obs.*grady);
	cmRates(denominator<1e-8) = 0;
	%}}}
	%% save {{{
	if saveFlag
		disp(['    Saving to ', saveFilename]);
		save([saveFilename], 'cmRates', 'time');
	end
	%}}}
