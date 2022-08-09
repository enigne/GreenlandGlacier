% To generate obs velocity using model data
%
% Last modified: 2022-08-08
function setObsVelocityFromModel(varargin)
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
	%GET save filename: timeSeries_Model_onmesh{{{
	sfilename = getfieldvalue(options, 'save filename', 'timeSeries_Model_onmesh');
	saveFilename = [projPath, resultsFolder, sfilename, '.mat'];
	% }}}
	%GET isSave: 1{{{
	saveflag = getfieldvalue(options, 'isSave', 1);
	% }}}


%% load {{{
% load model with obs constraint front
org=organizer('repository', [projPath, '/Models/', mdCALFINFolder], 'prefix', ['Model_' glacier '_'], 'steps', [0]);
disp(['Loading calving front and model velocity from ', mdCALFINFolder]);
md = loadmodel(org, stepName);
% load obs vel 
vx_obs = cell2mat({md.results.TransientSolution(:).Vx});
vy_obs = cell2mat({md.results.TransientSolution(:).Vy});
time = cell2mat({md.results.TransientSolution(:).time});
vel_obs = sqrt(vx_obs.^2+vy_obs.^2);
%}}}
%% save {{{
if saveflag
	disp(['Saving to ', saveFilename]);
	save(saveFilename, 'time', 'vx_obs', 'vy_obs', 'vel_obs');
end
%}}}
