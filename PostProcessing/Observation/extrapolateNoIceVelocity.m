% To extrapolate obs velocity to the region without ice
%
% Last modified: 2022-06-16

function extrapolateNoIceVelocity(varargin)
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
	vfilename = getfieldvalue(options, 'vdata filename', 'timeSeries_Obs_onmesh');
	vdatafile = [projPath, resultsFolder, vfilename, '.mat'];
	% }}}
	%GET save filename: timeSeries_Obs_onmesh_extrap{{{
	sfilename = getfieldvalue(options, 'save filename', 'timeSeries_Obs_onmesh_extrap');
	saveFilename = [projPath, resultsFolder, sfilename, '.mat'];
	% }}}
	%GET isSave: 1{{{
	saveflag = getfieldvalue(options, 'isSave', 1);
	% }}}


%% load {{{
% load model with obs constraint front
org=organizer('repository', [projPath, '/Models/', mdCALFINFolder], 'prefix', ['Model_' glacier '_'], 'steps', [0]);
disp(['Loading calving front from ', mdCALFINFolder]);
md = loadmodel(org, stepName);
% load obs vel 
disp(['Loading obs velocity from ', vdatafile]);
Vdata = load(vdatafile);
vx_obs = Vdata.vx_obs;
vy_obs = Vdata.vy_obs;
time = Vdata.time;
%}}}
% data processing{{{
icemask = cell2mat({md.results.TransientSolution(:).MaskIceLevelset});
Nt = length(time);
% extrapolate for the element at calving front only
disp('    Start extrapolating from inland to the ocean side');
for id = 1:Nt
	levelset = icemask(:,id); % notice CFLevelset has been modify to compute the gradient
	vx = vx_obs(:, id);
	vy = vy_obs(:, id);
	pos = find(max(levelset(md.mesh.elements),[],2)>0 & min(levelset(md.mesh.elements),[],2)<0);
	cx = md.mesh.x(md.mesh.elements(pos,:));
	cy = md.mesh.y(md.mesh.elements(pos,:));
	crvx = vx(md.mesh.elements(pos,:));
	crvy = vy(md.mesh.elements(pos,:));
	Fvx = scatteredInterpolant(cx(:), cy(:), crvx(:), 'nearest','nearest');
	Fvy = scatteredInterpolant(cx(:), cy(:), crvy(:), 'nearest','nearest');
	newvx = Fvx(md.mesh.x, md.mesh.y);
	newvy = Fvy(md.mesh.x, md.mesh.y);
	posfloat = find(levelset>0);
	vx_obs(posfloat, id) = newvx(posfloat);
	vy_obs(posfloat, id) = newvy(posfloat);
end
vel_obs = sqrt(vx_obs.^2+vy_obs.^2);
%}}}
%% save {{{
if saveflag
	disp(['Saving to ', saveFilename]);
	save(saveFilename, 'time', 'vx_obs', 'vy_obs', 'vel_obs');
end
%}}}
